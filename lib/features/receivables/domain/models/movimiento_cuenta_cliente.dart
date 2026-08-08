import '../../../sales/domain/models/venta_enums.dart';

/// Espejo de MovimientoCuentaClienteResumen en el backend — Tipo llega
/// como string ("Cargo"/"Abono") porque el backend no serializa enums
/// como número acá (usa ToString(), ver ObtenerCuentaPorCobrarQuery).
class MovimientoCuentaCliente {
  const MovimientoCuentaCliente({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.fechaVencimiento,
    required this.motivo,
    required this.medioPago,
    required this.fechaMovimiento,
  });

  factory MovimientoCuentaCliente.fromJson(Map<String, dynamic> json) => MovimientoCuentaCliente(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        monto: (json['monto'] as num).toDouble(),
        fechaVencimiento: json['fechaVencimiento'] == null ? null : DateTime.parse(json['fechaVencimiento'] as String),
        motivo: json['motivo'] as String?,
        medioPago: _medioPagoDesdeString(json['medioPago'] as String?),
        fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
      );

  final String id;
  final String tipo;
  final double monto;
  final DateTime? fechaVencimiento;
  final String? motivo;
  final MedioPago? medioPago;
  final DateTime fechaMovimiento;

  bool get esCargo => tipo == 'Cargo';

  static MedioPago? _medioPagoDesdeString(String? valor) {
    if (valor == null) return null;
    return MedioPago.values.firstWhere((m) => m.name == _aCamelCase(valor), orElse: () => MedioPago.efectivo);
  }

  static String _aCamelCase(String pascalCase) =>
      pascalCase.isEmpty ? pascalCase : pascalCase[0].toLowerCase() + pascalCase.substring(1);
}
