import 'venta_enums.dart';

/// Una línea de pago al confirmar una Venta al Contado — ver
/// Venta.Confirmar en el backend, que exige que la suma de todas
/// coincida exacto con el Total (soporta pago mixto). Vacía si la Venta
/// es a Crédito.
class PagoInput {
  const PagoInput({required this.medioPago, required this.monto, this.notaCreditoClienteId, this.anticipoOrdenTrabajoId});

  final MedioPago medioPago;
  final double monto;

  /// Obligatorio solo cuando medioPago es notaCredito — identifica qué
  /// NotaCreditoCliente Disponible se está usando para pagar.
  final String? notaCreditoClienteId;

  /// Obligatorio solo cuando medioPago es anticipo — identifica qué
  /// AnticipoOrdenTrabajo Disponible se está usando para pagar.
  final String? anticipoOrdenTrabajoId;

  Map<String, dynamic> toJson() => {
        'medioPago': medioPago.valorApi,
        'monto': monto,
        'notaCreditoClienteId': notaCreditoClienteId,
        'anticipoOrdenTrabajoId': anticipoOrdenTrabajoId,
      };
}
