/// Espejo de SolicitudCreditoPendienteResumen (ListarSolicitudesCreditoPendientesQuery
/// en el backend) — una fila de la cola de trabajo de quien autoriza Cupo
/// de Crédito (ver "customers.clientes.autorizarcredito").
class SolicitudCreditoPendiente {
  const SolicitudCreditoPendiente({
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.cupoCreditoActual,
    this.plazoPagoIdActual,
    required this.cupoCreditoSolicitado,
    this.plazoPagoIdSolicitado,
    this.observacion,
    required this.solicitadoPorUsuarioId,
    required this.fechaSolicitud,
  });

  factory SolicitudCreditoPendiente.fromJson(Map<String, dynamic> json) => SolicitudCreditoPendiente(
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String,
        cupoCreditoActual: (json['cupoCreditoActual'] as num).toDouble(),
        plazoPagoIdActual: json['plazoPagoIdActual'] as String?,
        cupoCreditoSolicitado: (json['cupoCreditoSolicitado'] as num).toDouble(),
        plazoPagoIdSolicitado: json['plazoPagoIdSolicitado'] as String?,
        observacion: json['observacion'] as String?,
        solicitadoPorUsuarioId: json['solicitadoPorUsuarioId'] as String,
        fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      );

  final String clienteId;
  final String clienteNombre;
  final String clienteRut;
  final double cupoCreditoActual;
  final String? plazoPagoIdActual;
  final double cupoCreditoSolicitado;
  final String? plazoPagoIdSolicitado;

  /// Contexto que dejó quien solicitó — típicamente por qué pide un cupo nuevo/mayor teniendo uno ya vigente.
  final String? observacion;
  final String solicitadoPorUsuarioId;
  final DateTime fechaSolicitud;

  bool get tieneCupoVigente => cupoCreditoActual > 0;
}
