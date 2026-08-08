import 'venta_enums.dart';

/// Una línea de pago al confirmar una Venta al Contado — ver
/// Venta.Confirmar en el backend, que exige que la suma de todas
/// coincida exacto con el Total (soporta pago mixto). Vacía si la Venta
/// es a Crédito.
class PagoInput {
  const PagoInput({required this.medioPago, required this.monto});

  final MedioPago medioPago;
  final double monto;

  Map<String, dynamic> toJson() => {'medioPago': medioPago.valorApi, 'monto': monto};
}
