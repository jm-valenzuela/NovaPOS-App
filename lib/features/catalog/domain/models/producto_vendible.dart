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
  });

  factory ProductoVendible.fromJson(Map<String, dynamic> json) => ProductoVendible(
        varianteProductoId: json['varianteProductoId'] as String,
        productoId: json['productoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        codigoBarras: json['codigoBarras'] as String?,
        precioVenta: (json['precioVenta'] as num).toDouble(),
        unidadMedida: json['unidadMedida'] as int,
      );

  final String varianteProductoId;
  final String productoId;
  final String nombreProducto;
  final String sku;
  final String? codigoBarras;
  final double precioVenta;
  final int unidadMedida;

  UnidadMedida get unidad => UnidadMedida.desdeValor(unidadMedida);
}
