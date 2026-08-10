import 'movimiento_cuenta_proveedor.dart';

/// Espejo de CuentaPorPagarResumen en el backend (ObtenerCuentaPorPagarQuery).
class CuentaPorPagarDetalle {
  const CuentaPorPagarDetalle({
    required this.proveedorId,
    required this.nombreProveedor,
    required this.rutProveedor,
    required this.saldoActual,
    required this.movimientos,
  });

  factory CuentaPorPagarDetalle.fromJson(Map<String, dynamic> json) => CuentaPorPagarDetalle(
        proveedorId: json['proveedorId'] as String,
        nombreProveedor: json['nombreProveedor'] as String,
        rutProveedor: json['rutProveedor'] as String?,
        saldoActual: (json['saldoActual'] as num).toDouble(),
        movimientos: (json['movimientos'] as List<dynamic>)
            .map((m) => MovimientoCuentaProveedor.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  final String proveedorId;
  final String nombreProveedor;
  final String? rutProveedor;
  final double saldoActual;
  final List<MovimientoCuentaProveedor> movimientos;
}
