import 'package:novapos_app/features/catalog/domain/catalog_repository.dart';
import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/customers/domain/customer_repository.dart';
import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/inventory/domain/inventory_repository.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/sales/domain/models/cotizacion.dart';
import 'package:novapos_app/features/sales/domain/models/descuento_pendiente.dart';
import 'package:novapos_app/features/sales/domain/models/detalle_descuento_pendiente.dart';
import 'package:novapos_app/features/sales/domain/models/estado_descuento_venta.dart';
import 'package:novapos_app/features/sales/domain/models/resumen_venta.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/domain/sales_repository.dart';
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

  @override
  Future<List<CajaResumen>> listarCajas() async => cajasARetornar;

  @override
  Future<BodegaVenta?> obtenerBodegaVenta(String sucursalId) async => bodegaVentaARetornar;
}

class FakeInventoryRepository implements InventoryRepository {
  List<StockVariante> stockARetornar = [];
  String? ultimaBodegaId;
  List<String>? ultimasVarianteProductoIds;

  @override
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds}) async {
    ultimaBodegaId = bodegaId;
    ultimasVarianteProductoIds = varianteProductoIds;
    return stockARetornar;
  }
}

class FakeSalesRepository implements SalesRepository {
  String? errorAforzar;
  String ventaIdARetornar = 'venta-fake-id';
  double totalARetornar = 0;

  int vecesCrearLlamado = 0;
  String? ultimoCajaId;
  String? ultimoClienteId;
  final List<({String varianteProductoId, double cantidad})> lineasAgregadas = [];

  @override
  Future<String> crearVenta({required String cajaId, String? clienteId}) async {
    vecesCrearLlamado++;
    ultimoCajaId = cajaId;
    ultimoClienteId = clienteId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ventaIdARetornar;
  }

  @override
  Future<void> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad}) async {
    lineasAgregadas.add((varianteProductoId: varianteProductoId, cantidad: cantidad));
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<ResumenVenta> confirmarVenta(String ventaId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ResumenVenta.calcular(totalARetornar);
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
    int plazoPagoDias = 0,
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
    return clienteIdARetornar;
  }

  @override
  Future<void> actualizarCliente({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    int plazoPagoDias = 0,
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
  }

  @override
  Future<void> asignarRutCliente({required String clienteId, required String rut}) async {
    ultimoClienteIdConRutAsignado = clienteId;
    ultimoRutAsignado = rut;
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
