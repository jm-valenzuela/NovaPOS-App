/// Espejo de DescuentoPendienteResumen (ListarDescuentosPendientesQuery en
/// el backend) — una fila de la cola de trabajo de quien autoriza
/// descuentos (ver "sales.descuentos.autorizar").
class DescuentoPendiente {
  const DescuentoPendiente({
    required this.ventaId,
    required this.clienteId,
    required this.subtotalLineas,
    required this.porcentaje,
    required this.monto,
    required this.solicitadoPorUsuarioId,
    required this.fechaSolicitud,
  });

  factory DescuentoPendiente.fromJson(Map<String, dynamic> json) => DescuentoPendiente(
        ventaId: json['ventaId'] as String,
        clienteId: json['clienteId'] as String,
        subtotalLineas: (json['subtotalLineas'] as num).toDouble(),
        porcentaje: (json['porcentaje'] as num?)?.toDouble(),
        monto: (json['monto'] as num?)?.toDouble(),
        solicitadoPorUsuarioId: json['solicitadoPorUsuarioId'] as String,
        fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      );

  final String ventaId;
  final String clienteId;
  final double subtotalLineas;

  /// Mutuamente excluyentes — igual criterio que VarianteProducto en Catalog.
  final double? porcentaje;
  final double? monto;

  final String solicitadoPorUsuarioId;
  final DateTime fechaSolicitud;
}
