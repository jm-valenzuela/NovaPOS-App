/// Espejo de EstadoNotaCreditoCliente en NovaPOS.Domain.Returns.
enum EstadoNotaCreditoCliente {
  disponible(0),
  utilizada(1),
  reembolsada(2);

  const EstadoNotaCreditoCliente(this.valorApi);

  final int valorApi;

  static EstadoNotaCreditoCliente desdeValor(int valor) => EstadoNotaCreditoCliente.values
      .firstWhere((e) => e.valorApi == valor, orElse: () => EstadoNotaCreditoCliente.disponible);

  String get etiqueta => switch (this) {
        EstadoNotaCreditoCliente.disponible => 'Disponible',
        EstadoNotaCreditoCliente.utilizada => 'Utilizada',
        EstadoNotaCreditoCliente.reembolsada => 'Reembolsada',
      };
}

/// Espejo de NotaCreditoClienteResumen — una fila del historial de Notas de
/// Crédito de un Cliente, o del selector de pago con Nota en el Checkout
/// (soloDisponibles=true en ese caso).
class NotaCreditoClienteResumen {
  const NotaCreditoClienteResumen({
    required this.id,
    required this.folio,
    required this.montoTotal,
    required this.estado,
    required this.fechaEmision,
    required this.motivo,
  });

  factory NotaCreditoClienteResumen.fromJson(Map<String, dynamic> json) => NotaCreditoClienteResumen(
        id: json['id'] as String,
        folio: json['folio'] as String,
        montoTotal: (json['montoTotal'] as num).toDouble(),
        estado: EstadoNotaCreditoCliente.desdeValor(json['estado'] as int),
        fechaEmision: DateTime.parse(json['fechaEmision'] as String),
        motivo: json['motivo'] as String,
      );

  final String id;
  final String folio;
  final double montoTotal;
  final EstadoNotaCreditoCliente estado;
  final DateTime fechaEmision;
  final String motivo;
}
