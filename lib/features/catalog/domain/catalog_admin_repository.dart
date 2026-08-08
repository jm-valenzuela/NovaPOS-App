import 'models/clasificacion.dart';
import 'models/producto_admin.dart';

class CrearProductoResultado {
  const CrearProductoResultado({required this.productoId, required this.varianteProductoId});

  final String productoId;
  final String varianteProductoId;
}

abstract class CatalogAdminRepository {
  Future<List<Departamento>> listarDepartamentos();
  Future<List<SubDepartamento>> listarSubDepartamentos(String departamentoId);
  Future<List<Clase>> listarClases(String subDepartamentoId);
  Future<List<Subclase>> listarSubclases(String claseId);
  Future<List<Marca>> listarMarcas();
  Future<List<ProductoAdmin>> listarProductos();

  Future<String> crearDepartamento(String nombre);
  Future<String> crearSubDepartamento(String departamentoId, String nombre);
  Future<String> crearClase(String subDepartamentoId, String nombre);
  Future<String> crearSubclase(String claseId, String nombre);
  Future<String> crearMarca(String nombre);

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
    double? precioOferta,
    DateTime? ofertaDesde,
    DateTime? ofertaHasta,
  });

  Future<void> actualizarProducto({
    required String productoId,
    required String nombre,
    String? descripcion,
    required String subclaseId,
    required String marcaId,
  });

  Future<void> activarProducto(String productoId);
  Future<void> desactivarProducto(String productoId);

  /// Agrega una Variante adicional (ej. otro color/talla) a un Producto ya
  /// existente — a diferencia de crearProducto, no crea clasificación ni
  /// Producto nuevo, solo la Variante.
  Future<String> crearVariante({
    required String productoId,
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
    double? precioOferta,
    DateTime? ofertaDesde,
    DateTime? ofertaHasta,
  });

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
    double? precioOferta,
    DateTime? ofertaDesde,
    DateTime? ofertaHasta,
  });

  Future<void> activarVariante(String varianteProductoId);
  Future<void> desactivarVariante(String varianteProductoId);

  /// Para Variantes sin código de barras del proveedor — genera uno EAN-13
  /// interno y lo asigna. Falla si la Variante ya tiene uno.
  Future<String> generarCodigoBarras(String varianteProductoId);
}
