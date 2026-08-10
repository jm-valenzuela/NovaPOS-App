import 'inventory_enums.dart';

/// Espejo de LineaTarjetaExistencia — un renglón del Kardex. SaldoAcumulado
/// es el stock que quedaba justo después de este movimiento, no el saldo actual.
class LineaTarjetaExistencia {
  const LineaTarjetaExistencia({
    required this.fechaMovimiento,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    required this.saldoAcumulado,
  });

  factory LineaTarjetaExistencia.fromJson(Map<String, dynamic> json) => LineaTarjetaExistencia(
        fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
        tipo: TipoMovimientoInventario.desdeValor(json['tipo'] as int),
        cantidad: (json['cantidad'] as num).toDouble(),
        motivo: json['motivo'] as String?,
        saldoAcumulado: (json['saldoAcumulado'] as num).toDouble(),
      );

  final DateTime fechaMovimiento;
  final TipoMovimientoInventario tipo;
  final double cantidad;
  final String? motivo;
  final double saldoAcumulado;
}
