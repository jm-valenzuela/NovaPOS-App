import 'models/linea_devolucion_input.dart';
import 'models/nota_credito_cliente_resumen.dart';
import 'models/nota_credito_disponible_resumen.dart';
import 'models/venta_confirmada_resumen.dart';
import 'models/venta_para_devolucion_detalle.dart';

/// Contrato de Devoluciones — buscar la Venta Confirmada a devolver,
/// registrar la devolución (emite la Nota de Crédito), y consultar las
/// Notas de Crédito de un Cliente (historial o solo Disponibles, para el
/// selector de pago del Checkout).
abstract class ReturnsRepository {
  Future<List<VentaConfirmadaResumen>> listarVentasConfirmadas(String sucursalId);

  Future<VentaParaDevolucionDetalle> obtenerVentaParaDevolucion(String ventaId);

  Future<String> registrarDevolucion({
    required String ventaOrigenId,
    required String clienteId,
    required List<LineaDevolucionInput> lineas,
    required String motivo,
    required bool reembolsarEnEfectivo,
    String? sesionCajaId,
  });

  Future<List<NotaCreditoClienteResumen>> listarNotasCreditoCliente(String clienteId, {bool soloDisponibles = false});

  /// Notas Disponibles de cualquier Cliente de la Empresa — para el popup "Notas de crédito a devolver en efectivo" del menú de Caja del POS.
  Future<List<NotaCreditoDisponibleResumen>> listarNotasCreditoDisponibles();

  /// Reembolsa en efectivo, ahora, una Nota de Crédito que ya estaba Disponible de una devolución anterior.
  Future<void> reembolsarNotaCredito({required String notaCreditoId, required String sesionCajaId});
}
