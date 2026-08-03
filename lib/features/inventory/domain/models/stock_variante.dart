/// Espejo de StockResumen (ListarStockDeVariantesQuery en el backend).
class StockVariante {
  const StockVariante({required this.varianteProductoId, required this.cantidad});

  factory StockVariante.fromJson(Map<String, dynamic> json) => StockVariante(
        varianteProductoId: json['varianteProductoId'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
      );

  final String varianteProductoId;
  final double cantidad;
}
