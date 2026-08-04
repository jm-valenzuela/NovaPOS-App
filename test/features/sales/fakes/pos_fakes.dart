import 'package:novapos_app/features/catalog/domain/catalog_repository.dart';
import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/customers/domain/customer_repository.dart';
import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/inventory/domain/inventory_repository.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/sales/domain/models/resumen_venta.dart';
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
}

class FakeCustomerRepository implements CustomerRepository {
  List<ClienteResumen> resultadosARetornar = [];
  String? ultimoTexto;

  @override
  Future<List<ClienteResumen>> buscarClientes({String? texto}) async {
    ultimoTexto = texto;
    return resultadosARetornar;
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

const cajaUnica = CajaResumen(
  cajaId: 'caja-1',
  codigoCaja: 'CAJA-01',
  nombreCaja: 'Caja Principal',
  sucursalId: 'sucursal-1',
  nombreSucursal: 'Casa Matriz',
);

const bodegaVentaFixture = BodegaVenta(bodegaId: 'bodega-1', nombreBodega: 'Bodega Principal');

const clienteJuan = ClienteResumen(id: 'cliente-juan', rut: '76.123.456-0', nombre: 'Juan Pérez', email: null, telefono: null);
