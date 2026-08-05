import 'models/descuento_pendiente.dart';
import 'models/estado_descuento_venta.dart';
import 'models/resumen_venta.dart';

/// Contrato para el flujo de cobro del POS — Crear Venta, agregar cada
/// línea, confirmar. El carrito en sí es estado de cliente puro (ver
/// LineaCarrito); esto solo cubre la parte que sí toca al backend.
abstract class SalesRepository {
  Future<String> crearVenta({required String cajaId, String? clienteId});

  Future<void> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad});

  Future<ResumenVenta> confirmarVenta(String ventaId);

  /// El Cajero pide el descuento — porcentaje y monto son mutuamente
  /// excluyentes, mandar exactamente uno de los dos.
  Future<void> solicitarDescuentoGeneral({required String ventaId, double? porcentaje, double? monto});

  /// El POS del Cajero consulta esto mientras espera que alguien con
  /// "sales.descuentos.autorizar" resuelva la solicitud.
  Future<EstadoDescuentoVenta> obtenerEstadoDescuento(String ventaId);

  /// Cola de trabajo de quien autoriza descuentos.
  Future<List<DescuentoPendiente>> listarDescuentosPendientes();

  Future<void> autorizarDescuentoGeneral(String ventaId);

  Future<void> rechazarDescuentoGeneral({required String ventaId, required String motivo});
}
