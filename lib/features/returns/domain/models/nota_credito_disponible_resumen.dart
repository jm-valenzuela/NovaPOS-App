/// Espejo de NotaCreditoDisponibleResumen — fila liviana para el popup
/// "Notas de crédito a devolver en efectivo" del menú de Caja del POS:
/// el Cliente vuelve más tarde con una Nota que le quedó Disponible de
/// una devolución anterior y el Cajero se la paga en efectivo ahora.
class NotaCreditoDisponibleResumen {
  const NotaCreditoDisponibleResumen({
    required this.id,
    required this.folio,
    required this.clienteId,
    required this.clienteNombre,
    required this.montoTotal,
    required this.fechaEmision,
    required this.motivo,
  });

  factory NotaCreditoDisponibleResumen.fromJson(Map<String, dynamic> json) => NotaCreditoDisponibleResumen(
        id: json['id'] as String,
        folio: json['folio'] as String,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        montoTotal: (json['montoTotal'] as num).toDouble(),
        fechaEmision: DateTime.parse(json['fechaEmision'] as String),
        motivo: json['motivo'] as String,
      );

  final String id;
  final String folio;
  final String clienteId;
  final String clienteNombre;
  final double montoTotal;
  final DateTime fechaEmision;
  final String motivo;
}
