/// Espejo de SolicitudCreditoPendienteResumen (ListarSolicitudesCreditoPendientesQuery
/// en el backend) — una fila de la cola de trabajo de quien autoriza Cupo
/// de Crédito (ver "customers.clientes.autorizarcredito").
class SolicitudCreditoPendiente {
  const SolicitudCreditoPendiente({
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.cupoCreditoActual,
    required this.cupoCreditoSolicitado,
    this.plazoPagoIdSolicitado,
    required this.solicitadoPorUsuarioId,
    required this.fechaSolicitud,
  });

  factory SolicitudCreditoPendiente.fromJson(Map<String, dynamic> json) => SolicitudCreditoPendiente(
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String,
        cupoCreditoActual: (json['cupoCreditoActual'] as num).toDouble(),
        cupoCreditoSolicitado: (json['cupoCreditoSolicitado'] as num).toDouble(),
        plazoPagoIdSolicitado: json['plazoPagoIdSolicitado'] as String?,
        solicitadoPorUsuarioId: json['solicitadoPorUsuarioId'] as String,
        fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      );

  final String clienteId;
  final String clienteNombre;
  final String clienteRut;
  final double cupoCreditoActual;
  final double cupoCreditoSolicitado;
  final String? plazoPagoIdSolicitado;
  final String solicitadoPorUsuarioId;
  final DateTime fechaSolicitud;
}
