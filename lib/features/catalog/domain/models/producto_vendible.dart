import 'unidad_medida.dart';

/// Espejo de ProductoVendibleResumen (BuscarProductosVendiblesQuery en el backend).
class ProductoVendible {
  const ProductoVendible({
    required this.varianteProductoId,
    required this.productoId,
    required this.nombreProducto,
    required this.sku,
    required this.codigoBarras,
    required this.precioVenta,
    required this.unidadMedida,
    this.cantidadMinimaDescuentoVolumen,
    this.porcentajeDescuentoVolumen,
    this.cantidadPorGrupoPromocion,
    this.porcentajeDescuentoUnidadPromocion,
  });

  factory ProductoVendible.fromJson(Map<String, dynamic> json) => ProductoVendible(
        varianteProductoId: json['varianteProductoId'] as String,
        productoId: json['productoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        codigoBarras: json['codigoBarras'] as String?,
        precioVenta: (json['precioVenta'] as num).toDouble(),
        unidadMedida: json['unidadMedida'] as int,
        cantidadMinimaDescuentoVolumen: json['cantidadMinimaDescuentoVolumen'] as int?,
        porcentajeDescuentoVolumen: (json['porcentajeDescuentoVolumen'] as num?)?.toDouble(),
        cantidadPorGrupoPromocion: json['cantidadPorGrupoPromocion'] as int?,
        porcentajeDescuentoUnidadPromocion: (json['porcentajeDescuentoUnidadPromocion'] as num?)?.toDouble(),
      );

  final String varianteProductoId;
  final String productoId;
  final String nombreProducto;
  final String sku;
  final String? codigoBarras;
  final double precioVenta;
  final int unidadMedida;

  /// "Desde N unidades, X% dto." — ambos null si la Variante no tiene esta
  /// promoción configurada (ver VarianteProducto.CantidadMinimaDescuentoVolumen
  /// en el backend).
  final int? cantidadMinimaDescuentoVolumen;
  final double? porcentajeDescuentoVolumen;

  /// Promoción por grupo (2x1, 6x5, "segundo al 40%", etc.) — ambos null si
  /// no aplica. Mutuamente excluyente con el descuento por volumen de
  /// arriba (ver VarianteProducto.CantidadPorGrupoPromocion en el backend).
  final int? cantidadPorGrupoPromocion;
  final double? porcentajeDescuentoUnidadPromocion;

  UnidadMedida get unidad => UnidadMedida.desdeValor(unidadMedida);
}
