import '../domain/catalog_admin_repository.dart';
import '../domain/models/clasificacion.dart';
import '../domain/models/producto_admin.dart';
import 'catalog_admin_api.dart';

class CatalogAdminRepositoryImpl implements CatalogAdminRepository {
  CatalogAdminRepositoryImpl(this._api);

  final CatalogAdminApi _api;

  @override
  Future<List<Departamento>> listarDepartamentos() => _api.listarDepartamentos();

  @override
  Future<List<SubDepartamento>> listarSubDepartamentos(String departamentoId) =>
      _api.listarSubDepartamentos(departamentoId);

  @override
  Future<List<Clase>> listarClases(String subDepartamentoId) => _api.listarClases(subDepartamentoId);

  @override
  Future<List<Subclase>> listarSubclases(String claseId) => _api.listarSubclases(claseId);

  @override
  Future<List<Marca>> listarMarcas() => _api.listarMarcas();

  @override
  Future<List<ProductoAdmin>> listarProductos() => _api.listarProductos();

  @override
  Future<String> crearDepartamento(String nombre) => _api.crearDepartamento(nombre);

  @override
  Future<String> crearSubDepartamento(String departamentoId, String nombre) =>
      _api.crearSubDepartamento(departamentoId, nombre);

  @override
  Future<String> crearClase(String subDepartamentoId, String nombre) => _api.crearClase(subDepartamentoId, nombre);

  @override
  Future<String> crearSubclase(String claseId, String nombre) => _api.crearSubclase(claseId, nombre);

  @override
  Future<String> crearMarca(String nombre) => _api.crearMarca(nombre);

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
    double? precioOferta,
    DateTime? ofertaDesde,
    DateTime? ofertaHasta,
  }) =>
      _api.crearProducto(
        subclaseId: subclaseId,
        marcaId: marcaId,
        nombre: nombre,
        descripcion: descripcion,
        sku: sku,
        precioVenta: precioVenta,
        unidadMedida: unidadMedida,
        codigoBarras: codigoBarras,
        color: color,
        talla: talla,
        ubicacionFisica: ubicacionFisica,
        cantidadMinimaDescuentoVolumen: cantidadMinimaDescuentoVolumen,
        porcentajeDescuentoVolumen: porcentajeDescuentoVolumen,
        cantidadPorGrupoPromocion: cantidadPorGrupoPromocion,
        porcentajeDescuentoUnidadPromocion: porcentajeDescuentoUnidadPromocion,
        precioOferta: precioOferta,
        ofertaDesde: ofertaDesde,
        ofertaHasta: ofertaHasta,
      );

  @override
  Future<void> actualizarProducto({
    required String productoId,
    required String nombre,
    String? descripcion,
    required String subclaseId,
    required String marcaId,
  }) =>
      _api.actualizarProducto(
        productoId: productoId, nombre: nombre, descripcion: descripcion, subclaseId: subclaseId, marcaId: marcaId);

  @override
  Future<void> activarProducto(String productoId) => _api.activarProducto(productoId);

  @override
  Future<void> desactivarProducto(String productoId) => _api.desactivarProducto(productoId);

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
    double? precioOferta,
    DateTime? ofertaDesde,
    DateTime? ofertaHasta,
  }) =>
      _api.actualizarVariante(
        varianteProductoId: varianteProductoId,
        precioVenta: precioVenta,
        unidadMedida: unidadMedida,
        codigoBarras: codigoBarras,
        color: color,
        talla: talla,
        ubicacionFisica: ubicacionFisica,
        cantidadMinimaDescuentoVolumen: cantidadMinimaDescuentoVolumen,
        porcentajeDescuentoVolumen: porcentajeDescuentoVolumen,
        cantidadPorGrupoPromocion: cantidadPorGrupoPromocion,
        porcentajeDescuentoUnidadPromocion: porcentajeDescuentoUnidadPromocion,
        precioOferta: precioOferta,
        ofertaDesde: ofertaDesde,
        ofertaHasta: ofertaHasta,
      );

  @override
  Future<void> activarVariante(String varianteProductoId) => _api.activarVariante(varianteProductoId);

  @override
  Future<void> desactivarVariante(String varianteProductoId) => _api.desactivarVariante(varianteProductoId);

  @override
  Future<String> generarCodigoBarras(String varianteProductoId) => _api.generarCodigoBarras(varianteProductoId);
}
