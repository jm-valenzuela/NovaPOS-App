import 'movimiento_cuenta_cliente.dart';

/// Espejo de CuentaPorCobrarResumen en el backend (ObtenerCuentaPorCobrarQuery).
class CuentaPorCobrarDetalle {
  const CuentaPorCobrarDetalle({
    required this.clienteId,
    required this.nombreCliente,
    required this.rutCliente,
    required this.saldoActual,
    required this.movimientos,
  });

  factory CuentaPorCobrarDetalle.fromJson(Map<String, dynamic> json) => CuentaPorCobrarDetalle(
        clienteId: json['clienteId'] as String,
        nombreCliente: json['nombreCliente'] as String,
        rutCliente: json['rutCliente'] as String?,
        saldoActual: (json['saldoActual'] as num).toDouble(),
        movimientos: (json['movimientos'] as List<dynamic>)
            .map((m) => MovimientoCuentaCliente.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  final String clienteId;
  final String nombreCliente;
  final String? rutCliente;
  final double saldoActual;
  final List<MovimientoCuentaCliente> movimientos;
}
