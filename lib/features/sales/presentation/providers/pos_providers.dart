import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../catalog/data/catalog_repository_impl.dart';
import '../../../catalog/data/catalogo_api.dart';
import '../../../catalog/domain/catalog_repository.dart';
import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../tenancy/data/tenancy_api.dart';
import '../../../tenancy/data/tenancy_repository_impl.dart';
import '../../../tenancy/domain/models/caja_resumen.dart';
import '../../../tenancy/domain/tenancy_repository.dart';
import '../../data/sales_repository_impl.dart';
import '../../data/venta_api.dart';
import '../../domain/models/linea_carrito.dart';
import '../../domain/sales_repository.dart';

final catalogoApiProvider = Provider<CatalogoApi>((ref) => CatalogoApi(ref.watch(apiClientProvider)));
final tenancyApiProvider = Provider<TenancyApi>((ref) => TenancyApi(ref.watch(apiClientProvider)));
final ventaApiProvider = Provider<VentaApi>((ref) => VentaApi(ref.watch(apiClientProvider)));

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepositoryImpl(ref.watch(catalogoApiProvider)));
final tenancyRepositoryProvider =
    Provider<TenancyRepository>((ref) => TenancyRepositoryImpl(ref.watch(tenancyApiProvider)));
final salesRepositoryProvider = Provider<SalesRepository>((ref) => SalesRepositoryImpl(ref.watch(ventaApiProvider)));

/// Cajas de la Empresa del Usuario logueado — casi siempre una sola (la
/// auto-provisionada en UC-01), pero una Empresa real puede tener varias
/// Sucursales con su propia Caja cada una.
final cajasProvider = FutureProvider.autoDispose<List<CajaResumen>>((ref) async {
  return ref.watch(tenancyRepositoryProvider).listarCajas();
});

/// Con qué Caja está trabajando el Cajero en esta sesión de POS — null
/// hasta que se resuelve sola (una única Caja) o el Usuario elige entre
/// varias.
final cajaSeleccionadaProvider = StateProvider.autoDispose<CajaResumen?>((ref) => null);

class BusquedaProductosState {
  const BusquedaProductosState({this.resultados = const [], this.buscando = false, this.error});

  final List<ProductoVendible> resultados;
  final bool buscando;
  final String? error;

  BusquedaProductosState copyWith({List<ProductoVendible>? resultados, bool? buscando, String? error, bool limpiarError = false}) {
    return BusquedaProductosState(
      resultados: resultados ?? this.resultados,
      buscando: buscando ?? this.buscando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Búsqueda con debounce — evita disparar una llamada HTTP por cada
/// tecla mientras el Cajero escribe.
class BusquedaProductosController extends StateNotifier<BusquedaProductosState> {
  BusquedaProductosController(this._repository) : super(const BusquedaProductosState());

  final CatalogRepository _repository;
  Timer? _debounce;
  int _peticionEnCurso = 0;

  void buscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _ejecutarBusqueda(texto));
  }

  Future<void> _ejecutarBusqueda(String texto) async {
    final idDeEstaPeticion = ++_peticionEnCurso;
    state = state.copyWith(buscando: true, limpiarError: true);
    try {
      final resultados = await _repository.buscarProductos(texto: texto);
      // Descarta la respuesta si ya se disparó una búsqueda más nueva
      // mientras esta estaba en vuelo (evita que una respuesta lenta de
      // una búsqueda vieja pise el resultado de la más reciente).
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(resultados: resultados, buscando: false);
    } catch (e) {
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(buscando: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final busquedaProductosProvider =
    StateNotifierProvider.autoDispose<BusquedaProductosController, BusquedaProductosState>((ref) {
  return BusquedaProductosController(ref.watch(catalogRepositoryProvider));
});

class PosCartState {
  const PosCartState({this.lineas = const [], this.cobrando = false, this.error, this.totalCobrado});

  final List<LineaCarrito> lineas;
  final bool cobrando;
  final String? error;
  final double? totalCobrado;

  double get total => lineas.fold(0, (suma, linea) => suma + linea.subtotal);

  PosCartState copyWith({
    List<LineaCarrito>? lineas,
    bool? cobrando,
    String? error,
    bool limpiarError = false,
    bool limpiarTotalCobrado = false,
  }) {
    return PosCartState(
      lineas: lineas ?? this.lineas,
      cobrando: cobrando ?? this.cobrando,
      error: limpiarError ? null : (error ?? this.error),
      totalCobrado: limpiarTotalCobrado ? null : totalCobrado,
    );
  }
}

class PosCartController extends StateNotifier<PosCartState> {
  PosCartController(this._salesRepository) : super(const PosCartState());

  final SalesRepository _salesRepository;

  void agregarProducto(ProductoVendible producto) {
    final indice = state.lineas.indexWhere((l) => l.producto.varianteProductoId == producto.varianteProductoId);
    if (indice == -1) {
      state = state.copyWith(lineas: [...state.lineas, LineaCarrito(producto: producto, cantidad: 1)]);
    } else {
      _actualizarCantidad(indice, state.lineas[indice].cantidad + 1);
    }
  }

  void cambiarCantidad(String varianteProductoId, double cantidad) {
    final indice = state.lineas.indexWhere((l) => l.producto.varianteProductoId == varianteProductoId);
    if (indice == -1) return;
    _actualizarCantidad(indice, cantidad);
  }

  void quitarLinea(String varianteProductoId) {
    state = state.copyWith(
      lineas: state.lineas.where((l) => l.producto.varianteProductoId != varianteProductoId).toList(),
    );
  }

  void _actualizarCantidad(int indice, double nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      state = state.copyWith(lineas: [...state.lineas]..removeAt(indice));
      return;
    }
    final lineas = [...state.lineas];
    lineas[indice] = lineas[indice].copyWith(cantidad: nuevaCantidad);
    state = state.copyWith(lineas: lineas);
  }

  /// Crea la Venta recién ahora, agrega cada línea del carrito y
  /// confirma — el carrito no toca el backend antes de esto (ver
  /// LineaCarrito). Si algo falla a mitad de camino, la Venta queda en
  /// Borrador en el servidor sin las líneas restantes — se informa el
  /// error y el carrito local NO se vacía, para que el Cajero pueda
  /// reintentar sin volver a tipear todo.
  Future<void> cobrar({required String cajaId, String? clienteId}) async {
    if (state.lineas.isEmpty) return;

    state = state.copyWith(cobrando: true, limpiarError: true, limpiarTotalCobrado: true);
    try {
      final ventaId = await _salesRepository.crearVenta(cajaId: cajaId, clienteId: clienteId);

      for (final linea in state.lineas) {
        await _salesRepository.agregarLinea(
          ventaId: ventaId,
          varianteProductoId: linea.producto.varianteProductoId,
          cantidad: linea.cantidad,
        );
      }

      final total = await _salesRepository.confirmarVenta(ventaId);

      state = PosCartState(totalCobrado: total);
    } catch (e) {
      state = state.copyWith(cobrando: false, error: e.toString());
    }
  }

  void limpiarVentaCobrada() {
    state = state.copyWith(limpiarTotalCobrado: true);
  }
}

final posCartProvider = StateNotifierProvider.autoDispose<PosCartController, PosCartState>((ref) {
  return PosCartController(ref.watch(salesRepositoryProvider));
});
