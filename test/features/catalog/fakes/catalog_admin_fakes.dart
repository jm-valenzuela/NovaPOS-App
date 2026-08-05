import 'package:novapos_app/features/catalog/domain/catalog_admin_repository.dart';
import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/domain/models/producto_admin.dart';

class FakeCatalogAdminRepository implements CatalogAdminRepository {
  List<Departamento> departamentos = [];
  List<SubDepartamento> subDepartamentos = [];
  List<Clase> clases = [];
  List<Subclase> subclases = [];
  List<Marca> marcas = [];
  List<ProductoAdmin> productos = [];

  String? errorAforzar;
  int vecesListarProductosLlamado = 0;
  String? ultimoDepartamentoIdPedido;
  String? ultimoSubDepartamentoIdPedido;
  String? ultimoClaseIdPedido;

  CrearProductoResultado resultadoCrear = const CrearProductoResultado(productoId: 'producto-nuevo', varianteProductoId: 'variante-nueva');

  final List<String> productosActivados = [];
  final List<String> productosDesactivados = [];
  final List<String> variantesActivadas = [];
  final List<String> variantesDesactivadas = [];
  Map<String, dynamic>? ultimaActualizacionProducto;
  Map<String, dynamic>? ultimaActualizacionVariante;

  void _fallarSiCorresponde() {
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<List<Departamento>> listarDepartamentos() async {
    _fallarSiCorresponde();
    return departamentos;
  }

  @override
  Future<List<SubDepartamento>> listarSubDepartamentos(String departamentoId) async {
    _fallarSiCorresponde();
    ultimoDepartamentoIdPedido = departamentoId;
    return subDepartamentos.where((s) => s.departamentoId == departamentoId).toList();
  }

  @override
  Future<List<Clase>> listarClases(String subDepartamentoId) async {
    _fallarSiCorresponde();
    ultimoSubDepartamentoIdPedido = subDepartamentoId;
    return clases.where((c) => c.subDepartamentoId == subDepartamentoId).toList();
  }

  @override
  Future<List<Subclase>> listarSubclases(String claseId) async {
    _fallarSiCorresponde();
    ultimoClaseIdPedido = claseId;
    return subclases.where((s) => s.claseId == claseId).toList();
  }

  @override
  Future<List<Marca>> listarMarcas() async {
    _fallarSiCorresponde();
    return marcas;
  }

  @override
  Future<List<ProductoAdmin>> listarProductos() async {
    _fallarSiCorresponde();
    vecesListarProductosLlamado++;
    return productos;
  }

  @override
  Future<String> crearDepartamento(String nombre) async {
    final id = 'depto-${departamentos.length + 1}';
    departamentos = [...departamentos, Departamento(id: id, nombre: nombre, activo: true)];
    return id;
  }

  @override
  Future<String> crearSubDepartamento(String departamentoId, String nombre) async {
    final id = 'subdepto-${subDepartamentos.length + 1}';
    subDepartamentos = [...subDepartamentos, SubDepartamento(id: id, departamentoId: departamentoId, nombre: nombre, activo: true)];
    return id;
  }

  @override
  Future<String> crearClase(String subDepartamentoId, String nombre) async {
    final id = 'clase-${clases.length + 1}';
    clases = [...clases, Clase(id: id, subDepartamentoId: subDepartamentoId, nombre: nombre, activa: true)];
    return id;
  }

  @override
  Future<String> crearSubclase(String claseId, String nombre) async {
    final id = 'subclase-${subclases.length + 1}';
    subclases = [...subclases, Subclase(id: id, claseId: claseId, nombre: nombre, activa: true)];
    return id;
  }

  @override
  Future<String> crearMarca(String nombre) async {
    final id = 'marca-${marcas.length + 1}';
    marcas = [...marcas, Marca(id: id, nombre: nombre, activa: true)];
    return id;
  }

  @override
  Future<CrearProductoResultado> crearProducto({
    required String subclaseId,
    required String marcaId,
    required String nombre,
    String? descripcion,
    required String sku,
    required double precioVenta,
    required int unidadMedida,
    String? codigoBarras,
    String? color,
    String? talla,
    String? ubicacionFisica,
    int? cantidadMinimaDescuentoVolumen,
    double? porcentajeDescuentoVolumen,
    int? cantidadPorGrupoPromocion,
    double? porcentajeDescuentoUnidadPromocion,
  }) async {
    _fallarSiCorresponde();
    return resultadoCrear;
  }

  @override
  Future<void> actualizarProducto({
    required String productoId,
    required String nombre,
    String? descripcion,
    required String subclaseId,
    required String marcaId,
  }) async {
    _fallarSiCorresponde();
    ultimaActualizacionProducto = {
      'productoId': productoId,
      'nombre': nombre,
      'descripcion': descripcion,
      'subclaseId': subclaseId,
      'marcaId': marcaId,
    };
  }

  @override
  Future<void> activarProducto(String productoId) async {
    _fallarSiCorresponde();
    productosActivados.add(productoId);
  }

  @override
  Future<void> desactivarProducto(String productoId) async {
    _fallarSiCorresponde();
    productosDesactivados.add(productoId);
  }

  @override
  Future<void> actualizarVariante({
    required String varianteProductoId,
    required double precioVenta,
    required int unidadMedida,
    String? codigoBarras,
    String? color,
    String? talla,
    String? ubicacionFisica,
    int? cantidadMinimaDescuentoVolumen,
    double? porcentajeDescuentoVolumen,
    int? cantidadPorGrupoPromocion,
    double? porcentajeDescuentoUnidadPromocion,
  }) async {
    _fallarSiCorresponde();
    ultimaActualizacionVariante = {
      'varianteProductoId': varianteProductoId,
      'precioVenta': precioVenta,
      'unidadMedida': unidadMedida,
    };
  }

  @override
  Future<void> activarVariante(String varianteProductoId) async {
    _fallarSiCorresponde();
    variantesActivadas.add(varianteProductoId);
  }

  @override
  Future<void> desactivarVariante(String varianteProductoId) async {
    _fallarSiCorresponde();
    variantesDesactivadas.add(varianteProductoId);
  }

  String codigoBarrasARetornar = '2012345678905';
  final List<String> codigosBarrasGenerados = [];

  @override
  Future<String> generarCodigoBarras(String varianteProductoId) async {
    _fallarSiCorresponde();
    codigosBarrasGenerados.add(varianteProductoId);
    return codigoBarrasARetornar;
  }
}

const productoPoleraAdmin = ProductoAdmin(
  productoId: 'producto-polera',
  nombre: 'Polera Nike Dri-Fit',
  descripcion: 'Original',
  departamentoId: 'depto-vestuario',
  departamentoNombre: 'Vestuario',
  subclaseId: 'subclase-1',
  subclaseNombre: 'Manga Corta',
  marcaId: 'marca-1',
  marcaNombre: 'Nike',
  activo: true,
  variantes: [
    VarianteAdmin(
      varianteProductoId: 'variante-polera-az-m',
      sku: 'POLNIKE-AZ-M',
      codigoBarras: '7801234567890',
      color: 'Azul',
      talla: 'M',
      precioVenta: 19990,
      unidadMedida: 0,
      ubicacionFisica: 'Pasillo 3',
      activa: true,
    ),
  ],
);

const productoZapatillaAdmin = ProductoAdmin(
  productoId: 'producto-zapatilla',
  nombre: 'Zapatilla Adidas Running',
  descripcion: null,
  departamentoId: 'depto-calzado',
  departamentoNombre: 'Calzado',
  subclaseId: 'subclase-2',
  subclaseNombre: 'Deportivo',
  marcaId: 'marca-2',
  marcaNombre: 'Adidas',
  activo: true,
  variantes: [
    VarianteAdmin(
      varianteProductoId: 'variante-zapatilla-42',
      sku: 'ZAPADI-42',
      codigoBarras: '7809876543210',
      color: null,
      talla: '42',
      precioVenta: 39990,
      unidadMedida: 0,
      ubicacionFisica: null,
      activa: true,
    ),
  ],
);
