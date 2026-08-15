/// Espejo de RetiroCajaPendienteResumen (ListarRetirosPendientesQuery en el
/// backend) — una fila de la cola de trabajo de quien autoriza Retiros de
/// Caja (ver "cash.retiros.autorizar").
class RetiroCajaPendiente {
  const RetiroCajaPendiente({
    required this.id,
    required this.sesionCajaId,
    required this.monto,
    required this.motivo,
    required this.solicitadoPorUsuarioId,
    required this.fechaSolicitud,
  });

  factory RetiroCajaPendiente.fromJson(Map<String, dynamic> json) => RetiroCajaPendiente(
        id: json['id'] as String,
        sesionCajaId: json['sesionCajaId'] as String,
        monto: (json['monto'] as num).toDouble(),
        motivo: json['motivo'] as String,
        solicitadoPorUsuarioId: json['solicitadoPorUsuarioId'] as String,
        fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      );

  final String id;
  final String sesionCajaId;
  final double monto;
  final String motivo;
  final String solicitadoPorUsuarioId;
  final DateTime fechaSolicitud;
}
