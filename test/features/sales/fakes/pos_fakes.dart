import 'package:novapos_app/features/catalog/domain/catalog_repository.dart';
import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/customers/domain/customer_repository.dart';
import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/customers/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/customers/domain/models/solicitud_credito_pendiente.dart';
import 'package:novapos_app/features/inventory/domain/inventory_repository.dart';
import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/inventory/domain/models/tarjeta_existencia.dart';
import 'package:novapos_app/features/inventory/domain/models/toma_inventario.dart';
import 'package:novapos_app/features/inventory/domain/models/traslado_inventario.dart';
import 'package:novapos_app/features/sales/domain/models/cotizacion.dart';
import 'package:novapos_app/features/sales/domain/models/descuento_pendiente.dart';
import 'package:novapos_app/features/sales/domain/models/detalle_descuento_pendiente.dart';
import 'package:novapos_app/features/sales/domain/models/estado_descuento_venta.dart';
import 'package:novapos_app/features/sales/domain/models/pago_input.dart';
import 'package:novapos_app/features/sales/domain/models/resumen_venta.dart';
import 'package:novapos_app/features/sales/domain/models/venta_detalle.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/domain/sales_repository.dart';
import 'package:novapos_app/features/tenancy/domain/models/bodega_resumen.dart';
import 'package:novapos_app/features/tenancy/domain/models/bodega_venta.dart';
import 'package:novapos_app/features/tenancy/domain/models/caja_resumen.dart';
import 'package:novapos_app/features/tenancy/domain/tenancy_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  List<ProductoVendible> resultadosARetornar = [];
  String? ultimoTexto;
  String? ultimoDepartamentoId;
  int vecesLlamado = 0;

  @override
  Future<List<ProductoVendible>> buscarProductos({String? texto, String? departamentoId}) async {
    vecesLlamado++;
    ultimoTexto = texto;
    ultimoDepartamentoId = departamentoId;
    return resultadosARetornar;
  }
}

class FakeTenancyRepository implements TenancyRepository {
  List<CajaResumen> cajasARetornar = [];
  BodegaVenta? bodegaVentaARetornar;
  List<BodegaResumen> bodegasARetornar = [];

  @override
  Future<List<CajaResumen>> listarCajas() async => cajasARetornar;

  @override
  Future<BodegaVenta?> obtenerBodegaVenta(String sucursalId) async => bodegaVentaARetornar;

  @override
  Future<List<BodegaResumen>> listarBodegas() async => bodegasARetornar;
}

class FakeInventoryRepository implements InventoryRepository {
  List<StockVariante> stockARetornar = [];
  String? ultimaBodegaId;
  List<String>? ultimasVarianteProductoIds;

  List<TomaInventarioListado> tomasARetornar = [];
  TomaInventarioDetalle? tomaDetalleARetornar;
  String tomaIdARetornar = 'toma-fake-id';
  String? ultimoFiltroBodegaTomas;
  EstadoTomaInventario? ultimoFiltroEstadoTomas;

  List<TrasladoListado> trasladosARetornar = [];
  TrasladoDetalle? trasladoDetalleARetornar;
  String trasladoIdARetornar = 'traslado-fake-id';
  String? ultimoFiltroBodegaTraslados;
  EstadoTraslado? ultimoFiltroEstadoTraslados;

  List<LineaTarjetaExistencia> tarjetaExistenciaARetornar = [];

  @override
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds}) async {
    ultimaBodegaId = bodegaId;
    ultimasVarianteProductoIds = varianteProductoIds;
    return stockARetornar;
  }

  @override
  Future<List<TomaInventarioListado>> listarTomas({String? bodegaId, EstadoTomaInventario? estado}) async {
    ultimoFiltroBodegaTomas = bodegaId;
    ultimoFiltroEstadoTomas = estado;
    return tomasARetornar;
  }

  @override
  Future<String> abrirToma({required String bodegaId}) async => tomaIdARetornar;

  @override
  Future<void> registrarConteo({required String tomaId, required String varianteProductoId, required double cantidadContada}) async {}

  @override
  Future<void> cerrarToma(String tomaId) async {}

  @override
  Future<TomaInventarioDetalle> obtenerToma(String tomaId) async => tomaDetalleARetornar!;

  @override
  Future<List<TrasladoListado>> listarTraslados({String? bodegaId, EstadoTraslado? estado}) async {
    ultimoFiltroBodegaTraslados = bodegaId;
    ultimoFiltroEstadoTraslados = estado;
    return trasladosARetornar;
  }

  @override
  Future<String> crearTraslado({required String bodegaOrigenId, required String bodegaDestinoId}) async => trasladoIdARetornar;

  @override
  Future<void> agregarLineaTraslado({required String trasladoId, required String varianteProductoId, required double cantidad}) async {}

  @override
  Future<void> enviarTraslado(String trasladoId) async {}

  @override
  Future<void> recibirTraslado({required String trasladoId, required Map<String, double> lineas}) async {}

  @override
  Future<TrasladoDetalle> obtenerTraslado(String trasladoId) async => trasladoDetalleARetornar!;

  @override
  Future<List<LineaTarjetaExistencia>> obtenerTarjetaExistencia({required String bodegaId, required String varianteProductoId}) async =>
      tarjetaExistenciaARetornar;
}

class FakeSalesRepository implements SalesRepository {
  String? errorAforzar;
  String ventaIdARetornar = 'venta-fake-id';
  double totalARetornar = 0;

  int vecesCrearLlamado = 0;
  String? ultimoCajaId;
  String? ultimoClienteId;
  final List<({String varianteProductoId, double cantidad})> lineasAgregadas = [];
  final List<({String ventaId, String lineaVentaId, double cantidad})> lineasActualizadas = [];
  final List<({String ventaId, String lineaVentaId})> lineasQuitadas = [];

  @override
  Future<String> crearVenta({required String cajaId, String? clienteId}) async {
    vecesCrearLlamado++;
    ultimoCajaId = cajaId;
    ultimoClienteId = clienteId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ventaIdARetornar;
  }

  @override
  Future<String> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad}) async {
    lineasAgregadas.add((varianteProductoId: varianteProductoId, cantidad: cantidad));
    if (errorAforzar != null) throw Exception(errorAforzar);
    return 'linea-fake-${lineasAgregadas.length}';
  }

  @override
  Future<void> actualizarLinea({required String ventaId, required String lineaVentaId, required double cantidad}) async {
    lineasActualizadas.add((ventaId: ventaId, lineaVentaId: lineaVentaId, cantidad: cantidad));
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> quitarLinea({required String ventaId, required String lineaVentaId}) async {
    lineasQuitadas.add((ventaId: ventaId, lineaVentaId: lineaVentaId));
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  final List<({String ventaId, String descripcion, double monto})> lineasLibresAgregadas = [];
  final List<({String ventaId, String lineaLibreId})> lineasLibresQuitadas = [];

  @override
  Future<String> agregarLineaLibre({required String ventaId, required String descripcion, required double monto}) async {
    lineasLibresAgregadas.add((ventaId: ventaId, descripcion: descripcion, monto: monto));
    if (errorAforzar != null) throw Exception(errorAforzar);
    return 'linea-libre-fake-${lineasLibresAgregadas.length}';
  }

  @override
  Future<void> quitarLineaLibre({required String ventaId, required String lineaLibreId}) async {
    lineasLibresQuitadas.add((ventaId: ventaId, lineaLibreId: lineaLibreId));
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  TipoDocumento? ultimoTipoDocumento;
  List<PagoInput>? ultimosPagos;

  /// Si se setea, se devuelve tal cual en vez de ResumenVenta.calcular —
  /// permite simular una respuesta con datos de DTE (folio/RUT/TED) para
  /// probar el botón "Imprimir" en el diálogo de Venta confirmada.
  ResumenVenta? resumenConfirmarARetornar;

  @override
  Future<ResumenVenta> confirmarVenta({
    required String ventaId,
    required TipoDocumento tipoDocumento,
    required List<PagoInput> pagos,
  }) async {
    ultimoTipoDocumento = tipoDocumento;
    ultimosPagos = pagos;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return resumenConfirmarARetornar ?? ResumenVenta.calcular(totalARetornar);
  }

  String? ultimaVentaIdDescuento;
  double? ultimoPorcentajeSolicitado;
  double? ultimoMontoSolicitado;
  EstadoDescuentoVenta? estadoDescuentoARetornar;
  List<DescuentoPendiente> pendientesARetornar = [];
  DetalleDescuentoPendiente? detalleDescuentoARetornar;
  String? ultimaVentaIdDetalleConsultada;
  String? ultimaVentaIdAutorizada;
  String? ultimaVentaIdRechazada;
  String? ultimoMotivoRechazo;

  @override
  Future<void> solicitarDescuentoGeneral({required String ventaId, double? porcentaje, double? monto}) async {
    ultimaVentaIdDescuento = ventaId;
    ultimoPorcentajeSolicitado = porcentaje;
    ultimoMontoSolicitado = monto;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<EstadoDescuentoVenta> obtenerEstadoDescuento(String ventaId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return estadoDescuentoARetornar ??
        EstadoDescuentoVenta(
          ventaId: ventaId,
          estado: EstadoDescuentoGeneral.pendiente,
          total: totalARetornar,
          subtotalLineas: totalARetornar,
          motivoRechazo: null,
        );
  }

  @override
  Future<List<DescuentoPendiente>> listarDescuentosPendientes() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return pendientesARetornar;
  }

  @override
  Future<DetalleDescuentoPendiente> obtenerDetalleDescuentoPendiente(String ventaId) async {
    ultimaVentaIdDetalleConsultada = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return detalleDescuentoARetornar ??
        DetalleDescuentoPendiente(
          ventaId: ventaId,
          clienteId: 'cliente-generico',
          clienteNombre: 'Cliente Genérico',
          clienteRut: null,
          subtotalLineas: totalARetornar,
          porcentaje: null,
          monto: null,
          lineas: const [],
        );
  }

  @override
  Future<void> autorizarDescuentoGeneral(String ventaId) async {
    ultimaVentaIdAutorizada = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> rechazarDescuentoGeneral({required String ventaId, required String motivo}) async {
    ultimaVentaIdRechazada = ventaId;
    ultimoMotivoRechazo = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  String? ultimaVentaIdMarcadaCotizacion;
  List<CotizacionResumen> cotizacionesARetornar = [];
  String? ultimaSucursalIdCotizacionesConsultada;
  CotizacionDetalle? cotizacionDetalleARetornar;
  String? ultimaVentaIdCotizacionConsultada;

  @override
  Future<void> marcarComoCotizacion(String ventaId) async {
    ultimaVentaIdMarcadaCotizacion = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<List<CotizacionResumen>> listarCotizaciones(String sucursalId) async {
    ultimaSucursalIdCotizacionesConsultada = sucursalId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return cotizacionesARetornar;
  }

  @override
  Future<CotizacionDetalle> obtenerCotizacion(String ventaId) async {
    ultimaVentaIdCotizacionConsultada = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return cotizacionDetalleARetornar ??
        CotizacionDetalle(
          ventaId: ventaId,
          clienteId: 'cliente-generico',
          clienteNombre: 'Cliente Genérico',
          clienteRut: null,
          subtotalLineas: totalARetornar,
          total: totalARetornar,
          estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
          descuentoGeneralPorcentaje: null,
          descuentoGeneralMonto: null,
          lineas: const [],
        );
  }

  VentaDetalle? ventaDetalleARetornar;
  String? ultimaVentaIdConsultada;

  @override
  Future<VentaDetalle> obtenerVenta(String ventaId) async {
    ultimaVentaIdConsultada = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ventaDetalleARetornar ??
        VentaDetalle(id: ventaId, neto: totalARetornar, iva: 0, total: totalARetornar, lineas: const [], pagos: const []);
  }
}

class FakeCustomerRepository implements CustomerRepository {
  List<ClienteResumen> resultadosARetornar = [];
  String? ultimoTexto;
  String clienteIdARetornar = 'cliente-nuevo';
  String? ultimoClienteIdActualizado;
  String? ultimoRutCreado;
  String? ultimoRutAsignado;
  String? ultimoClienteIdConRutAsignado;
  bool crearLlamado = false;
  String? ultimoGiro;
  String? ultimaDireccion;
  String? ultimaComuna;
  String? ultimaCiudad;
  String? ultimoNombreCreado;
  String? ultimoEmailCreado;
  String? ultimoTelefonoCreado;
  String? ultimoPlazoPagoIdCreado;
  String? ultimoPlazoPagoIdActualizado;
  String? errorAlCrear;

  @override
  Future<List<ClienteResumen>> buscarClientes({String? texto}) async {
    ultimoTexto = texto;
    return resultadosARetornar;
  }

  @override
  Future<String> crearCliente({
    required String nombre,
    String? rut,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    if (errorAlCrear != null) throw Exception(errorAlCrear);
    crearLlamado = true;
    ultimoRutCreado = rut;
    ultimoGiro = giro;
    ultimaDireccion = direccion;
    ultimaComuna = comuna;
    ultimaCiudad = ciudad;
    ultimoNombreCreado = nombre;
    ultimoEmailCreado = email;
    ultimoTelefonoCreado = telefono;
    ultimoPlazoPagoIdCreado = plazoPagoId;
    return clienteIdARetornar;
  }

  @override
  Future<void> actualizarCliente({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    ultimoClienteIdActualizado = clienteId;
    ultimoGiro = giro;
    ultimaDireccion = direccion;
    ultimaComuna = comuna;
    ultimaCiudad = ciudad;
    ultimoPlazoPagoIdActualizado = plazoPagoId;
  }

  @override
  Future<void> asignarRutCliente({required String clienteId, required String rut}) async {
    ultimoClienteIdConRutAsignado = clienteId;
    ultimoRutAsignado = rut;
  }

  List<SolicitudCreditoPendiente> solicitudesCreditoPendientesARetornar = [];
  String? ultimoClienteIdSolicitudCredito;
  double? ultimoCupoSolicitado;
  String? ultimoPlazoPagoIdSolicitado;
  String? ultimaObservacionSolicitudCredito;
  String? ultimoClienteIdCreditoAutorizado;
  String? ultimoClienteIdCreditoRechazado;
  String? ultimoMotivoRechazoCredito;

  @override
  Future<void> solicitarCreditoCliente({
    required String clienteId,
    required double cupoSolicitado,
    String? plazoPagoIdSolicitado,
    String? observacion,
  }) async {
    ultimoClienteIdSolicitudCredito = clienteId;
    ultimoCupoSolicitado = cupoSolicitado;
    ultimoPlazoPagoIdSolicitado = plazoPagoIdSolicitado;
    ultimaObservacionSolicitudCredito = observacion;
  }

  @override
  Future<void> autorizarCreditoCliente(String clienteId) async {
    ultimoClienteIdCreditoAutorizado = clienteId;
  }

  @override
  Future<void> rechazarCreditoCliente({required String clienteId, required String motivo}) async {
    ultimoClienteIdCreditoRechazado = clienteId;
    ultimoMotivoRechazoCredito = motivo;
  }

  @override
  Future<List<SolicitudCreditoPendiente>> listarSolicitudesCreditoPendientes() async => solicitudesCreditoPendientesARetornar;

  List<PlazoPago> plazosPagoARetornar = [];
  String? ultimoNombrePlazoPagoCreado;
  List<int>? ultimasDiasCuotasCreadas;
  String plazoPagoIdARetornar = 'plazo-nuevo';
  String? ultimoPlazoPagoIdActivado;
  String? ultimoPlazoPagoIdDesactivado;

  @override
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas}) async {
    ultimoNombrePlazoPagoCreado = nombre;
    ultimasDiasCuotasCreadas = diasCuotas;
    return plazoPagoIdARetornar;
  }

  @override
  Future<List<PlazoPago>> listarPlazosPago() async => plazosPagoARetornar;

  @override
  Future<void> activarPlazoPago(String plazoPagoId) async {
    ultimoPlazoPagoIdActivado = plazoPagoId;
  }

  @override
  Future<void> desactivarPlazoPago(String plazoPagoId) async {
    ultimoPlazoPagoIdDesactivado = plazoPagoId;
  }
}

const productoCocaCola = ProductoVendible(
  varianteProductoId: 'variante-coca',
  productoId: 'producto-coca',
  nombreProducto: 'Coca Cola 1.5L',
  sku: 'COCA-15',
  codigoBarras: '7801234500001',
  precioVenta: 1500,
  unidadMedida: 0,
);

const productoPan = ProductoVendible(
  varianteProductoId: 'variante-pan',
  productoId: 'producto-pan',
  nombreProducto: 'Pan Marraqueta',
  sku: 'PAN-MARR',
  codigoBarras: null,
  precioVenta: 800,
  unidadMedida: 1,
);

const productoTornillo = ProductoVendible(
  varianteProductoId: 'variante-tornillo',
  productoId: 'producto-tornillo',
  nombreProducto: 'Tornillo Autoperforante 1"',
  sku: 'FER-TORN-1',
  codigoBarras: null,
  precioVenta: 100,
  unidadMedida: 0,
  cantidadMinimaDescuentoVolumen: 15,
  porcentajeDescuentoVolumen: 5,
);

const productoGaseosaPromo = ProductoVendible(
  varianteProductoId: 'variante-gaseosa-promo',
  productoId: 'producto-gaseosa-promo',
  nombreProducto: 'Bebida Cola 1.5L (2x1)',
  sku: 'PROMO-2X1',
  codigoBarras: null,
  precioVenta: 1000,
  unidadMedida: 0,
  cantidadPorGrupoPromocion: 2,
  porcentajeDescuentoUnidadPromocion: 100,
);

/// Rango de fechas deliberadamente amplio para que la oferta esté siempre
/// vigente sin importar cuándo corra el test.
final productoOferta = ProductoVendible(
  varianteProductoId: 'variante-oferta',
  productoId: 'producto-oferta',
  nombreProducto: 'Televisor 55" 4K',
  sku: 'TV-55-4K',
  codigoBarras: null,
  precioVenta: 500000,
  unidadMedida: 0,
  precioOferta: 399990,
  ofertaDesde: DateTime(2020, 1, 1),
  ofertaHasta: DateTime(2099, 12, 31),
);

const cajaUnica = CajaResumen(
  cajaId: 'caja-1',
  codigoCaja: 'CAJA-01',
  nombreCaja: 'Caja Principal',
  sucursalId: 'sucursal-1',
  nombreSucursal: 'Casa Matriz',
);

const bodegaVentaFixture = BodegaVenta(bodegaId: 'bodega-1', nombreBodega: 'Bodega Principal');

const clienteJuan = ClienteResumen(id: 'cliente-juan', rut: '76.123.456-0', nombre: 'Juan Pérez', email: null, telefono: null);
