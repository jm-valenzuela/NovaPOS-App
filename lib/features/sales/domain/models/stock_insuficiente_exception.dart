/// Un Producto sin stock suficiente en la Bodega de la Venta — espejo de
/// LineaSinStockSuficiente en el backend (ver ConfirmarVentaCommand).
class LineaSinStockSuficiente {
  const LineaSinStockSuficiente({required this.nombreProducto, required this.cantidadDisponible, required this.cantidadPedida});

  factory LineaSinStockSuficiente.fromJson(Map<String, dynamic> json) => LineaSinStockSuficiente(
        nombreProducto: json['nombreProducto'] as String,
        cantidadDisponible: (json['cantidadDisponible'] as num).toDouble(),
        cantidadPedida: (json['cantidadPedida'] as num).toDouble(),
      );

  final String nombreProducto;
  final double cantidadDisponible;
  final double cantidadPedida;
}

/// Se distingue de ApiException genérica porque el POS reacciona distinto:
/// en vez de solo mostrar el mensaje, ofrece "Cancelar" o "Continuar de
/// todas formas" (reintentando confirmarVenta con permitirVentaSinStock)
/// — ver PosCartController.cobrar y CheckoutDialog. Algunas Empresas no
/// llevan el inventario al día y necesitan poder vender igual.
class StockInsuficienteException implements Exception {
  const StockInsuficienteException(this.message, this.lineas);

  final String message;
  final List<LineaSinStockSuficiente> lineas;

  @override
  String toString() => message;
}
