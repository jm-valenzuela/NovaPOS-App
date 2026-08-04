import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../catalog/data/catalog_repository_impl.dart';
import '../../../catalog/data/catalogo_api.dart';
import '../../../catalog/domain/catalog_repository.dart';
import '../../../catalog/domain/models/clasificacion.dart';
import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../catalog/presentation/providers/catalog_admin_providers.dart' show catalogAdminRepositoryProvider;
import '../../../customers/data/customer_api.dart';
import '../../../customers/data/customer_repository_impl.dart';
import '../../../customers/domain/customer_repository.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../inventory/data/inventario_api.dart';
import '../../../inventory/data/inventory_repository_impl.dart';
import '../../../inventory/domain/inventory_repository.dart';
import '../../../tenancy/data/tenancy_api.dart';
import '../../../tenancy/data/tenancy_repository_impl.dart';
import '../../../tenancy/domain/models/bodega_venta.dart';
import '../../../tenancy/domain/models/caja_resumen.dart';
import '../../../tenancy/domain/tenancy_repository.dart';
import '../../data/sales_repository_impl.dart';
import '../../data/venta_api.dart';
import '../../domain/models/linea_carrito.dart';
import '../../domain/models/resumen_venta.dart';
import '../../domain/sales_repository.dart';

final catalogoApiProvider = Provider<CatalogoApi>((ref) => CatalogoApi(ref.watch(apiClientProvider)));
final tenancyApiProvider = Provider<TenancyApi>((ref) => TenancyApi(ref.watch(apiClientProvider)));
final ventaApiProvider = Provider<VentaApi>((ref) => VentaApi(ref.watch(apiClientProvider)));
final inventarioApiProvider = Provider<InventarioApi>((ref) => InventarioApi(ref.watch(apiClientProvider)));
final customerApiProvider = Provider<CustomerApi>((ref) => CustomerApi(ref.watch(apiClientProvider)));

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepositoryImpl(ref.watch(catalogoApiProvider)));
final tenancyRepositoryProvider =
    Provider<TenancyRepository>((ref) => TenancyRepositoryImpl(ref.watch(tenancyApiProvider)));
final salesRepositoryProvider = Provider<SalesRepository>((ref) => SalesRepositoryImpl(ref.watch(ventaApiProvider)));
final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => InventoryRepositoryImpl(ref.watch(inventarioApiProvider)));
final customerRepositoryProvider =
    Provider<CustomerRepository>((ref) => CustomerRepositoryImpl(ref.watch(customerApiProvider)));

/// Cliente elegido para la Venta actual — null significa "Cliente
/// Genérico" (el backend resuelve ese caso solo si ClienteId no viene en
/// CrearVentaCommand, ver CrearVentaCommandHandler). Se limpia después de
/// cada cobro para no arrastrar el Cliente de la Venta anterior a la siguiente.
final clienteSeleccionadoProvider = StateProvider.autoDispose<ClienteResumen?>((ref) => null);

class BusquedaClientesState {
  const BusquedaClientesState({this.resultados = const [], this.buscando = false});

  final List<ClienteResumen> resultados;
  final bool buscando;

  BusquedaClientesState copyWith({List<ClienteResumen>? resultados, bool? buscando}) {
    return BusquedaClientesState(resultados: resultados ?? this.resultados, buscando: buscando ?? this.buscando);
  }
}

/// Búsqueda con debounce para el diálogo de selección de Cliente — mismo
/// patrón que BusquedaProductosController, sin el enriquecido de stock.
class BusquedaClientesController extends StateNotifier<BusquedaClientesState> {
  BusquedaClientesController(this._repository) : super(const BusquedaClientesState());

  final CustomerRepository _repository;
  Timer? _debounce;
  int _peticionEnCurso = 0;

  void buscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _ejecutarBusqueda(texto));
  }

  Future<void> _ejecutarBusqueda(String texto) async {
    final idDeEstaPeticion = ++_peticionEnCurso;
    state = state.copyWith(buscando: true);
    try {
      final resultados = await _repository.buscarClientes(texto: texto);
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(resultados: resultados, buscando: false);
    } catch (_) {
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(buscando: false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final busquedaClientesProvider =
    StateNotifierProvider.autoDispose<BusquedaClientesController, BusquedaClientesState>((ref) {
  return BusquedaClientesController(ref.watch(customerRepositoryProvider));
});

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

/// Bodega de venta de la Sucursal de la Caja seleccionada — resuelta una
/// vez por sesión de POS (no cambia mientras no cambie la Caja). Null
/// mientras no haya Caja elegida o la Sucursal no tenga Bodega de venta
/// configurada; en ese caso simplemente no se muestra stock (no bloquea
/// la venta, que es lo importante).
final bodegaVentaProvider = FutureProvider.autoDispose<BodegaVenta?>((ref) async {
  final caja = ref.watch(cajaSeleccionadaProvider);
  if (caja == null) return null;
  return ref.watch(tenancyRepositoryProvider).obtenerBodegaVenta(caja.sucursalId);
});

/// Categorías del POS = Departamentos de Catalog (el nivel más alto de
/// la jerarquía) — se listan una vez al entrar al POS, para las tabs de filtro.
final departamentosProvider = FutureProvider.autoDispose<List<Departamento>>((ref) async {
  return ref.watch(catalogAdminRepositoryProvider).listarDepartamentos();
});

/// Tab de categoría seleccionada — null = "Todos" (sin filtro).
final departamentoSeleccionadoProvider = StateProvider.autoDispose<String?>((ref) => null);

class BusquedaProductosState {
  const BusquedaProductosState({this.resultados = const [], this.stock = const {}, this.buscando = false, this.error});

  final List<ProductoVendible> resultados;

  /// Stock por VarianteProductoId — una Variante ausente de este mapa no
  /// tiene Existencia registrada en la Bodega actual (no es lo mismo que
  /// stock cero), o todavía no se resolvió la Bodega de venta.
  final Map<String, double> stock;
  final bool buscando;
  final String? error;

  BusquedaProductosState copyWith({
    List<ProductoVendible>? resultados,
    Map<String, double>? stock,
    bool? buscando,
    String? error,
    bool limpiarError = false,
  }) {
    return BusquedaProductosState(
      resultados: resultados ?? this.resultados,
      stock: stock ?? this.stock,
      buscando: buscando ?? this.buscando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Búsqueda con debounce — evita disparar una llamada HTTP por cada
/// tecla mientras el Cajero escribe. Enriquece los resultados con stock
/// en una segunda llamada (si hay Bodega resuelta) — el stock nunca
/// bloquea la búsqueda: si esa llamada falla, los resultados igual se
/// muestran, solo sin el dato de stock.
class BusquedaProductosController extends StateNotifier<BusquedaProductosState> {
  BusquedaProductosController(this._repository, this._inventoryRepository) : super(const BusquedaProductosState());

  final CatalogRepository _repository;
  final InventoryRepository _inventoryRepository;
  Timer? _debounce;
  int _peticionEnCurso = 0;

  void buscar(String texto, {String? departamentoId, String? bodegaId}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _ejecutarBusqueda(texto, departamentoId, bodegaId));
  }

  Future<void> _ejecutarBusqueda(String texto, String? departamentoId, String? bodegaId) async {
    final idDeEstaPeticion = ++_peticionEnCurso;
    state = state.copyWith(buscando: true, limpiarError: true);
    try {
      final resultados = await _repository.buscarProductos(texto: texto, departamentoId: departamentoId);
      // Descarta la respuesta si ya se disparó una búsqueda más nueva
      // mientras esta estaba en vuelo (evita que una respuesta lenta de
      // una búsqueda vieja pise el resultado de la más reciente).
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(resultados: resultados, stock: const {}, buscando: false);

      if (bodegaId != null && resultados.isNotEmpty) {
        await _cargarStock(idDeEstaPeticion, bodegaId, resultados.map((p) => p.varianteProductoId).toList());
      }
    } catch (e) {
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(buscando: false, error: e.toString());
    }
  }

  Future<void> _cargarStock(int idDeEstaPeticion, String bodegaId, List<String> varianteProductoIds) async {
    try {
      final stock = await _inventoryRepository.listarStock(bodegaId: bodegaId, varianteProductoIds: varianteProductoIds);
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(stock: {for (final s in stock) s.varianteProductoId: s.cantidad});
    } catch (_) {
      // El stock es informativo — si falla, los resultados de búsqueda ya mostrados no se tocan.
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
  return BusquedaProductosController(ref.watch(catalogRepositoryProvider), ref.watch(inventoryRepositoryProvider));
});

class PosCartState {
  const PosCartState({this.lineas = const [], this.cobrando = false, this.error, this.resumenCobrado});

  final List<LineaCarrito> lineas;
  final bool cobrando;
  final String? error;

  /// Desglose real devuelto por el backend al confirmar — solo se llena
  /// tras un cobro exitoso, para el diálogo de venta cobrada.
  final ResumenVenta? resumenCobrado;

  double get total => lineas.fold(0, (suma, linea) => suma + linea.subtotal);

  /// Desglose en vivo mientras se arma el carrito (antes de que exista una
  /// Venta real en el servidor) — mismo cálculo que el backend, ver ResumenVenta.calcular.
  ResumenVenta get resumen => ResumenVenta.calcular(total);

  PosCartState copyWith({
    List<LineaCarrito>? lineas,
    bool? cobrando,
    String? error,
    bool limpiarError = false,
    bool limpiarResumenCobrado = false,
  }) {
    return PosCartState(
      lineas: lineas ?? this.lineas,
      cobrando: cobrando ?? this.cobrando,
      error: limpiarError ? null : (error ?? this.error),
      resumenCobrado: limpiarResumenCobrado ? null : resumenCobrado,
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

    state = state.copyWith(cobrando: true, limpiarError: true, limpiarResumenCobrado: true);
    try {
      final ventaId = await _salesRepository.crearVenta(cajaId: cajaId, clienteId: clienteId);

      for (final linea in state.lineas) {
        await _salesRepository.agregarLinea(
          ventaId: ventaId,
          varianteProductoId: linea.producto.varianteProductoId,
          cantidad: linea.cantidad,
        );
      }

      final resumen = await _salesRepository.confirmarVenta(ventaId);

      state = PosCartState(resumenCobrado: resumen);
    } catch (e) {
      state = state.copyWith(cobrando: false, error: e.toString());
    }
  }

  void limpiarVentaCobrada() {
    state = state.copyWith(limpiarResumenCobrado: true);
  }
}

final posCartProvider = StateNotifierProvider.autoDispose<PosCartController, PosCartState>((ref) {
  return PosCartController(ref.watch(salesRepositoryProvider));
});
