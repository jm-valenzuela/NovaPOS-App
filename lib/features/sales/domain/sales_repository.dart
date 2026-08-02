/// Contrato para el flujo de cobro del POS — Crear Venta, agregar cada
/// línea, confirmar. El carrito en sí es estado de cliente puro (ver
/// LineaCarrito); esto solo cubre la parte que sí toca al backend.
abstract class SalesRepository {
  Future<String> crearVenta({required String cajaId, String? clienteId});

  Future<void> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad});

  Future<double> confirmarVenta(String ventaId);
}
