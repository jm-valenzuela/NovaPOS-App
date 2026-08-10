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
import '../../domain/models/cotizacion.dart';
import '../../domain/models/linea_carrito.dart';
import '../../domain/models/pago_input.dart';
import '../../domain/models/resumen_venta.dart';
import '../../domain/models/venta_enums.dart';
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

  /// Sin debounce — para un código de barras recién escaneado, que ya es
  /// un valor exacto y completo (esperar 350ms no aporta nada acá).
  Future<void> buscarInmediato(String texto, {String? departamentoId, String? bodegaId}) {
    _debounce?.cancel();
    return _ejecutarBusqueda(texto, departamentoId, bodegaId);
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
  const PosCartState({
    this.lineas = const [],
    this.cobrando = false,
    this.error,
    this.resumenCobrado,
    this.ventaId,
    this.estadoDescuento = EstadoDescuentoGeneral.sinSolicitar,
    this.descuentoPorcentaje,
    this.descuentoMonto,
    this.motivoRechazoDescuento,
    this.solicitandoDescuento = false,
    this.procesandoCotizacion = false,
  });

  final List<LineaCarrito> lineas;
  final bool cobrando;
  final String? error;

  /// Desglose real devuelto por el backend al confirmar — solo se llena
  /// tras un cobro exitoso, para el diálogo de venta cobrada.
  final ResumenVenta? resumenCobrado;

  /// Null hasta que se solicita un descuento, se guarda como Cotización o
  /// se rescata una — recién ahí hay una Venta real en el servidor (ver
  /// PosCartController.solicitarDescuento/guardarCotizacion/cargarCotizacion),
  /// antes de eso el carrito es 100% local. Con esto asignado, cada
  /// edición (agregar/quitar/cambiar cantidad) se sincroniza contra el
  /// backend en vez de mutar solo el estado local — ver carritoBloqueado
  /// para cuándo la edición en sí queda prohibida.
  final String? ventaId;

  final EstadoDescuentoGeneral estadoDescuento;

  /// Mutuamente excluyentes — lo que el Cajero pidió, para mostrarlo
  /// mientras se espera la resolución.
  final double? descuentoPorcentaje;
  final double? descuentoMonto;

  final String? motivoRechazoDescuento;
  final bool solicitandoDescuento;

  /// true mientras se guarda o se rescata una Cotización — deshabilita el
  /// menú de Cotización en la UI para evitar doble-tap.
  final bool procesandoCotizacion;

  /// Solo mientras un descuento general está Pendiente (alguien lo está
  /// evaluando ahora mismo) o Autorizado (el monto ya se validó contra un
  /// Subtotal específico) — ver Venta.GarantizarLineasEditables en el
  /// backend, que rechaza editar líneas en esos dos estados exactamente.
  /// Desde SinSolicitar o Rechazado el carrito sigue editable (sincroniza
  /// contra el backend si ventaId ya existe, ver agregarProducto/
  /// cambiarCantidad/quitarLinea).
  bool get carritoBloqueado =>
      estadoDescuento == EstadoDescuentoGeneral.pendiente || estadoDescuento == EstadoDescuentoGeneral.autorizado;

  /// No se puede volver a pedir mientras ya hay uno Pendiente (esperando
  /// resolución) o ya Autorizado (no tiene sentido pedir otro encima) —
  /// sí se puede tras un Rechazado, para pedir un monto distinto.
  bool get puedeSolicitarDescuento =>
      lineas.isNotEmpty &&
      !solicitandoDescuento &&
      estadoDescuento != EstadoDescuentoGeneral.pendiente &&
      estadoDescuento != EstadoDescuentoGeneral.autorizado;

  double get total => lineas.fold(0, (suma, linea) => suma + linea.subtotal);

  double get montoDescuentoAplicado {
    if (estadoDescuento != EstadoDescuentoGeneral.autorizado) return 0;
    if (descuentoPorcentaje != null) return total * descuentoPorcentaje! / 100;
    return descuentoMonto ?? 0;
  }

  double get totalConDescuento => total - montoDescuentoAplicado;

  /// Desglose en vivo mientras se arma el carrito (antes de que exista una
  /// Venta real en el servidor) — mismo cálculo que el backend, ver ResumenVenta.calcular.
  /// Ya incluye el descuento general una vez autorizado.
  ResumenVenta get resumen => ResumenVenta.calcular(totalConDescuento);

  PosCartState copyWith({
    List<LineaCarrito>? lineas,
    bool? cobrando,
    String? error,
    bool limpiarError = false,
    bool limpiarResumenCobrado = false,
    bool? solicitandoDescuento,
    bool? procesandoCotizacion,
  }) {
    return PosCartState(
      lineas: lineas ?? this.lineas,
      cobrando: cobrando ?? this.cobrando,
      error: limpiarError ? null : (error ?? this.error),
      resumenCobrado: limpiarResumenCobrado ? null : resumenCobrado,
      ventaId: ventaId,
      estadoDescuento: estadoDescuento,
      descuentoPorcentaje: descuentoPorcentaje,
      descuentoMonto: descuentoMonto,
      motivoRechazoDescuento: motivoRechazoDescuento,
      solicitandoDescuento: solicitandoDescuento ?? this.solicitandoDescuento,
      procesandoCotizacion: procesandoCotizacion ?? this.procesandoCotizacion,
    );
  }
}

class PosCartController extends StateNotifier<PosCartState> {
  PosCartController(this._salesRepository) : super(const PosCartState());

  final SalesRepository _salesRepository;

  /// `cantidad` es 1 por defecto (un producto por Unidad, ej. una botella
  /// más cada vez que se toca). Para productos por Kilogramo/Litro, quien
  /// llama pasa el peso/volumen exacto pedido al Cajero (ver
  /// CantidadPesableDialog en PosScreen) — si la Variante ya estaba en el
  /// carrito, se SUMA a lo ya pesado, no lo reemplaza (permite pesar el
  /// mismo producto en más de una tanda).
  /// Con un descuento general Pendiente o Autorizado, el carrito está
  /// bloqueado (ver carritoBloqueado) — se informa por qué, no se ignora
  /// en silencio. Fuera de eso, si ya existe una Venta en el servidor
  /// (ventaId != null — se pidió un descuento antes y fue Rechazado, se
  /// guardó como Cotización, o se rescató una), la línea se agrega también
  /// contra el backend para no desincronizar el Total real que Confirmar()
  /// va a cobrar.
  Future<void> agregarProducto(ProductoVendible producto, {double cantidad = 1}) async {
    if (state.carritoBloqueado) {
      state = state.copyWith(
        error: 'No puedes agregar más productos: hay un descuento general Pendiente o Autorizado para esta venta.',
      );
      return;
    }
    final indice = state.lineas.indexWhere((l) => l.producto.varianteProductoId == producto.varianteProductoId);
    if (indice != -1) {
      await _actualizarCantidad(indice, state.lineas[indice].cantidad + cantidad);
      return;
    }

    final ventaId = state.ventaId;
    if (ventaId == null) {
      state = state.copyWith(lineas: [...state.lineas, LineaCarrito(producto: producto, cantidad: cantidad)]);
      return;
    }

    try {
      final lineaVentaId = await _salesRepository.agregarLinea(
        ventaId: ventaId,
        varianteProductoId: producto.varianteProductoId,
        cantidad: cantidad,
      );
      state = state.copyWith(
        lineas: [...state.lineas, LineaCarrito(producto: producto, cantidad: cantidad, lineaVentaId: lineaVentaId)],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cambiarCantidad(String varianteProductoId, double cantidad) async {
    if (state.carritoBloqueado) return;
    final indice = state.lineas.indexWhere((l) => l.producto.varianteProductoId == varianteProductoId);
    if (indice == -1) return;
    await _actualizarCantidad(indice, cantidad);
  }

  Future<void> quitarLinea(String varianteProductoId) async {
    if (state.carritoBloqueado) return;
    final indice = state.lineas.indexWhere((l) => l.producto.varianteProductoId == varianteProductoId);
    if (indice == -1) return;
    await _quitarEnIndice(indice);
  }

  /// Reinicio completo a propósito (no solo las líneas): si ya se pidió un
  /// descuento, la Venta creada en el servidor queda abandonada en
  /// Borrador (no hay forma de cancelarla — mismo criterio que el resto
  /// del sistema, ver EstadoVenta.Anulada sin método que la use todavía).
  /// PosScreen pide confirmación antes de llamar esto si había un
  /// descuento en curso, ver _PosScreenState._vaciar.
  void vaciarCarrito() {
    state = const PosCartState();
  }

  Future<void> _quitarEnIndice(int indice) async {
    final linea = state.lineas[indice];
    final ventaId = state.ventaId;
    if (ventaId != null && linea.lineaVentaId != null) {
      try {
        await _salesRepository.quitarLinea(ventaId: ventaId, lineaVentaId: linea.lineaVentaId!);
      } catch (e) {
        state = state.copyWith(error: e.toString());
        return;
      }
    }
    state = state.copyWith(lineas: [...state.lineas]..removeAt(indice));
  }

  /// Si la línea ya está sincronizada con el backend (lineaVentaId no
  /// nulo), la edición se manda primero — si falla (ej. justo se volvió a
  /// Pendiente/Autorizado en otra pestaña), el estado local no cambia. Una
  /// vez sincronizada, se reconstruye la línea sin los campos históricos
  /// (porcentajeDescuentoVolumenHistorico, etc.): esos representan lo que
  /// se cobró en el pasado (ej. al rescatar una Cotización), y tras
  /// editar la Cantidad ya no describen esta línea — el Subtotal en
  /// pantalla vuelve a calcularse en vivo con las reglas vigentes del
  /// Producto (mismas que el backend acaba de aplicar), igual que
  /// cualquier línea agregada en esta sesión.
  Future<void> _actualizarCantidad(int indice, double nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      await _quitarEnIndice(indice);
      return;
    }

    final linea = state.lineas[indice];
    final ventaId = state.ventaId;
    if (ventaId != null && linea.lineaVentaId != null) {
      try {
        await _salesRepository.actualizarLinea(ventaId: ventaId, lineaVentaId: linea.lineaVentaId!, cantidad: nuevaCantidad);
      } catch (e) {
        state = state.copyWith(error: e.toString());
        return;
      }
    }

    final lineas = [...state.lineas];
    lineas[indice] = LineaCarrito(producto: linea.producto, cantidad: nuevaCantidad, lineaVentaId: linea.lineaVentaId);
    state = state.copyWith(lineas: lineas);
  }

  /// Crea la Venta recién ahora (salvo que ya exista por haberse pedido un
  /// descuento antes, ver solicitarDescuento), agrega cada línea del
  /// carrito y confirma — el carrito no toca el backend antes de esto
  /// (ver LineaCarrito). Si algo falla a mitad de camino, la Venta queda
  /// en Borrador en el servidor sin las líneas restantes — se informa el
  /// error y el carrito local NO se vacía, para que el Cajero pueda
  /// reintentar sin volver a tipear todo.
  /// tipoDocumento/pagos vienen del CheckoutDialog, mostrado antes de
  /// llamar acá — ver PosScreen. crearVenta hoy hardcodea FormaPago.contado
  /// (no hay selector de Crédito en el POS todavía), así que pagos siempre
  /// se espera no vacío.
  Future<void> cobrar({
    required String cajaId,
    String? clienteId,
    required TipoDocumento tipoDocumento,
    required List<PagoInput> pagos,
  }) async {
    if (state.lineas.isEmpty) return;
    if (state.estadoDescuento == EstadoDescuentoGeneral.pendiente) return;

    state = state.copyWith(cobrando: true, limpiarError: true, limpiarResumenCobrado: true);
    try {
      var ventaId = state.ventaId;
      if (ventaId == null) {
        ventaId = await _salesRepository.crearVenta(cajaId: cajaId, clienteId: clienteId);

        for (final linea in state.lineas) {
          await _salesRepository.agregarLinea(
            ventaId: ventaId,
            varianteProductoId: linea.producto.varianteProductoId,
            cantidad: linea.cantidad,
          );
        }
      }

      final resumen = await _salesRepository.confirmarVenta(ventaId: ventaId, tipoDocumento: tipoDocumento, pagos: pagos);

      state = PosCartState(resumenCobrado: resumen);
    } catch (e) {
      state = state.copyWith(cobrando: false, error: e.toString());
    }
  }

  void limpiarVentaCobrada() {
    state = state.copyWith(limpiarResumenCobrado: true);
  }

  /// Primera vez que se pide un descuento en este carrito: crea la Venta y
  /// agrega las líneas ahora mismo (antes de esto el carrito era 100%
  /// local) para tener un VentaId real contra el cual pedir el descuento.
  /// Pedidos siguientes (ej. el Supervisor rechazó y el Cajero pide un
  /// monto menor) reusan la misma Venta — porcentaje/monto son
  /// mutuamente excluyentes, mandar exactamente uno de los dos.
  Future<void> solicitarDescuento({
    required String cajaId,
    String? clienteId,
    double? porcentaje,
    double? monto,
  }) async {
    if (state.lineas.isEmpty) return;

    state = state.copyWith(solicitandoDescuento: true, limpiarError: true);
    try {
      var ventaId = state.ventaId;
      var lineas = state.lineas;
      if (ventaId == null) {
        ventaId = await _salesRepository.crearVenta(cajaId: cajaId, clienteId: clienteId);

        final lineasConId = <LineaCarrito>[];
        for (final linea in state.lineas) {
          final lineaVentaId = await _salesRepository.agregarLinea(
            ventaId: ventaId,
            varianteProductoId: linea.producto.varianteProductoId,
            cantidad: linea.cantidad,
          );
          lineasConId.add(linea.copyWith(lineaVentaId: lineaVentaId));
        }
        lineas = lineasConId;
      }

      await _salesRepository.solicitarDescuentoGeneral(ventaId: ventaId, porcentaje: porcentaje, monto: monto);

      state = PosCartState(
        lineas: lineas,
        ventaId: ventaId,
        estadoDescuento: EstadoDescuentoGeneral.pendiente,
        descuentoPorcentaje: porcentaje,
        descuentoMonto: monto,
      );
    } catch (e) {
      state = state.copyWith(solicitandoDescuento: false, error: e.toString());
    }
  }

  /// El POS llama esto mientras espera — ver SolicitarDescuentoDialog. Si
  /// el estado sigue Pendiente no cambia nada (el Supervisor, en el piso
  /// o en la oficina, todavía no resolvió); si falla la consulta se
  /// ignora en silencio y se reintenta en el próximo tick, sin tumbar la
  /// espera por un error de red puntual.
  Future<void> verificarEstadoDescuento() async {
    final ventaId = state.ventaId;
    if (ventaId == null || state.estadoDescuento != EstadoDescuentoGeneral.pendiente) return;
    try {
      final estado = await _salesRepository.obtenerEstadoDescuento(ventaId);
      if (estado.estado == EstadoDescuentoGeneral.pendiente) return;
      state = PosCartState(
        lineas: state.lineas,
        ventaId: state.ventaId,
        estadoDescuento: estado.estado,
        descuentoPorcentaje: state.descuentoPorcentaje,
        descuentoMonto: state.descuentoMonto,
        motivoRechazoDescuento: estado.motivoRechazo,
      );
    } catch (_) {
      // Informativo — se reintenta en el próximo tick del poller.
    }
  }

  /// Guarda el carrito actual como Cotización: crea la Venta y sus líneas
  /// recién ahora si aún no existían (mismo patrón lazy que cobrar()/
  /// solicitarDescuento()), la marca como Cotización y vacía el carrito
  /// para que el Cajero pueda empezar una venta nueva — la Cotización
  /// queda guardada en el servidor, disponible para "Rescatar" después.
  /// Devuelve el VentaId (para imprimir el ticket) o null si falló.
  Future<String?> guardarCotizacion({required String cajaId, String? clienteId}) async {
    if (state.lineas.isEmpty) return null;

    state = state.copyWith(procesandoCotizacion: true, limpiarError: true);
    try {
      var ventaId = state.ventaId;
      if (ventaId == null) {
        ventaId = await _salesRepository.crearVenta(cajaId: cajaId, clienteId: clienteId);

        for (final linea in state.lineas) {
          await _salesRepository.agregarLinea(
            ventaId: ventaId,
            varianteProductoId: linea.producto.varianteProductoId,
            cantidad: linea.cantidad,
          );
        }
      }

      await _salesRepository.marcarComoCotizacion(ventaId);

      state = const PosCartState();
      return ventaId;
    } catch (e) {
      state = state.copyWith(procesandoCotizacion: false, error: e.toString());
      return null;
    }
  }

  /// Rescata una Cotización guardada: reemplaza el carrito actual por sus
  /// líneas, con el carrito ya bloqueado (ventaId asignado) — igual que
  /// cualquier Venta ya persistida, no se puede seguir agregando/quitando
  /// líneas localmente (ver carritoBloqueado). El precio de cada línea es
  /// el precioUnitario real guardado en la Cotización (no el precio de
  /// lista actual, que puede haber cambiado desde entonces) — antes se
  /// usaba subtotal/cantidad, un promedio ya rebajado que mostraba, ej.,
  /// "$34.493" para un producto de $45.990 con "4x3" aplicado (bug real,
  /// reportado tras comparar el carrito rescatado contra el ticket
  /// impreso). LineaCarrito.subtotal ahora aplica el descuento histórico
  /// directamente sobre este precio real, así que el Total sigue
  /// coincidiendo exactamente con lo impreso al guardar. La UnidadMedida
  /// también viene resuelta desde el backend (antes quedaba fija en
  /// Unidad, así que un Producto por Kilogramo/Litro rescatado perdía el
  /// sufijo "kg"/"L" junto a la cantidad — bug real, ej. "1.6" en vez de
  /// "1.6 kg" para Pan Hallulla).
  void cargarCotizacion(CotizacionDetalle detalle) {
    final lineas = detalle.lineas
        .map((linea) => LineaCarrito(
              producto: ProductoVendible(
                varianteProductoId: linea.varianteProductoId,
                productoId: linea.varianteProductoId,
                nombreProducto: linea.nombreProducto,
                sku: linea.sku,
                codigoBarras: null,
                precioVenta: linea.precioUnitario,
                unidadMedida: linea.unidadMedida.valor,
                cantidadPorGrupoPromocion: linea.cantidadPorGrupoPromocion,
                porcentajeDescuentoUnidadPromocion: linea.porcentajeDescuentoUnidadPromocion,
              ),
              cantidad: linea.cantidad,
              lineaVentaId: linea.lineaVentaId,
              porcentajeDescuentoVolumenHistorico: linea.porcentajeDescuentoAplicado,
              montoDescuentoPromocionHistorico: linea.montoDescuentoPromocion,
              ofertaAplicadaHistorico: linea.precioOferta != null && linea.precioOferta == linea.precioUnitario,
              precioNormalHistorico:
                  (linea.precioOferta != null && linea.precioOferta == linea.precioUnitario) ? linea.precioVenta : null,
            ))
        .toList();

    // El descuento general se reenvía tal cual vino del backend — sin esto,
    // el Total mostrado al rescatar ignoraba silenciosamente un descuento
    // ya Autorizado (bug real, ver README).
    state = PosCartState(
      lineas: lineas,
      ventaId: detalle.ventaId,
      estadoDescuento: detalle.estadoDescuentoGeneral,
      descuentoPorcentaje: detalle.descuentoGeneralPorcentaje,
      descuentoMonto: detalle.descuentoGeneralMonto,
    );
  }

  /// Trae del servidor una Cotización guardada y reemplaza el carrito
  /// actual con su contenido (ver cargarCotizacion) — devuelve el detalle
  /// para que quien llama también pueda actualizar el Cliente seleccionado
  /// (estado aparte de PosCartState, ver clienteSeleccionadoProvider). Si
  /// falla la consulta, se informa por el mismo canal de error que el
  /// resto del carrito y el estado actual no se toca.
  Future<CotizacionDetalle?> rescatarCotizacion(String ventaId) async {
    state = state.copyWith(procesandoCotizacion: true, limpiarError: true);
    try {
      final detalle = await _salesRepository.obtenerCotizacion(ventaId);
      cargarCotizacion(detalle);
      return detalle;
    } catch (e) {
      state = state.copyWith(procesandoCotizacion: false, error: e.toString());
      return null;
    }
  }
}

final posCartProvider = StateNotifierProvider.autoDispose<PosCartController, PosCartState>((ref) {
  return PosCartController(ref.watch(salesRepositoryProvider));
});
