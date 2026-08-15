/// Una línea a devolver — espejo de LineaDevolucionRequest en el backend.
class LineaDevolucionInput {
  const LineaDevolucionInput({required this.varianteProductoId, required this.cantidad});

  final String varianteProductoId;
  final double cantidad;

  Map<String, dynamic> toJson() => {'varianteProductoId': varianteProductoId, 'cantidad': cantidad};
}
