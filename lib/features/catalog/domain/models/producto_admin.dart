/// Espejo de ProductoAdminResumen/VarianteAdminResumen (ListarProductosQuery
/// en el backend) — a diferencia de ProductoVendible (búsqueda para el
/// POS), incluye Productos/Variantes inactivos y los Ids/nombres de
/// clasificación, para la pantalla de administración de Catálogo.
class ProductoAdmin {
  const ProductoAdmin({
    required this.productoId,
    required this.nombre,
    required this.descripcion,
    required this.departamentoId,
    required this.departamentoNombre,
    required this.subclaseId,
    required this.subclaseNombre,
    required this.marcaId,
    required this.marcaNombre,
    required this.activo,
    required this.variantes,
  });

  factory ProductoAdmin.fromJson(Map<String, dynamic> json) => ProductoAdmin(
        productoId: json['productoId'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        departamentoId: json['departamentoId'] as String,
        departamentoNombre: json['departamentoNombre'] as String,
        subclaseId: json['subclaseId'] as String,
        subclaseNombre: json['subclaseNombre'] as String,
        marcaId: json['marcaId'] as String,
        marcaNombre: json['marcaNombre'] as String,
        activo: json['activo'] as bool,
        variantes: (json['variantes'] as List<dynamic>)
            .map((v) => VarianteAdmin.fromJson(v as Map<String, dynamic>))
            .toList(),
      );

  final String productoId;
  final String nombre;
  final String? descripcion;
  final String departamentoId;
  final String departamentoNombre;
  final String subclaseId;
  final String subclaseNombre;
  final String marcaId;
  final String marcaNombre;
  final bool activo;
  final List<VarianteAdmin> variantes;
}

class VarianteAdmin {
  const VarianteAdmin({
    required this.varianteProductoId,
    required this.sku,
    required this.codigoBarras,
    required this.color,
    required this.talla,
    required this.precioVenta,
    required this.unidadMedida,
    required this.ubicacionFisica,
    required this.activa,
    this.cantidadMinimaDescuentoVolumen,
    this.porcentajeDescuentoVolumen,
    this.cantidadPorGrupoPromocion,
    this.porcentajeDescuentoUnidadPromocion,
    this.precioOferta,
    this.ofertaDesde,
    this.ofertaHasta,
  });

  factory VarianteAdmin.fromJson(Map<String, dynamic> json) => VarianteAdmin(
        varianteProductoId: json['varianteProductoId'] as String,
        sku: json['sku'] as String,
        codigoBarras: json['codigoBarras'] as String?,
        color: json['color'] as String?,
        talla: json['talla'] as String?,
        precioVenta: (json['precioVenta'] as num).toDouble(),
        unidadMedida: json['unidadMedida'] as int,
        ubicacionFisica: json['ubicacionFisica'] as String?,
        activa: json['activa'] as bool,
        cantidadMinimaDescuentoVolumen: json['cantidadMinimaDescuentoVolumen'] as int?,
        porcentajeDescuentoVolumen: (json['porcentajeDescuentoVolumen'] as num?)?.toDouble(),
        cantidadPorGrupoPromocion: json['cantidadPorGrupoPromocion'] as int?,
        porcentajeDescuentoUnidadPromocion: (json['porcentajeDescuentoUnidadPromocion'] as num?)?.toDouble(),
        precioOferta: (json['precioOferta'] as num?)?.toDouble(),
        ofertaDesde: json['ofertaDesde'] == null ? null : DateTime.parse(json['ofertaDesde'] as String),
        ofertaHasta: json['ofertaHasta'] == null ? null : DateTime.parse(json['ofertaHasta'] as String),
      );

  final String varianteProductoId;
  final String sku;
  final String? codigoBarras;
  final String? color;
  final String? talla;
  final double precioVenta;
  final int unidadMedida;
  final String? ubicacionFisica;
  final bool activa;
  final int? cantidadMinimaDescuentoVolumen;
  final double? porcentajeDescuentoVolumen;
  final int? cantidadPorGrupoPromocion;
  final double? porcentajeDescuentoUnidadPromocion;

  /// Mutuamente excluyente con los dos campos de arriba (ver
  /// VarianteProducto.ValidarPromocionesNoSeSuperponen en el backend).
  final double? precioOferta;
  final DateTime? ofertaDesde;
  final DateTime? ofertaHasta;
}
