/// Espejo de EstadoSesionCaja en NovaPOS.Domain.Cash.
enum EstadoSesionCaja {
  abierta(0),
  cerrada(1);

  const EstadoSesionCaja(this.valorApi);

  final int valorApi;

  static EstadoSesionCaja desdeValor(int valor) =>
      EstadoSesionCaja.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoSesionCaja.abierta);
}

/// Espejo del resultado de ObtenerSesionCajaAbiertaQuery — un turno de
/// Caja abierto, desde que se declara el efectivo inicial hasta el cierre.
class SesionCaja {
  const SesionCaja({
    required this.id,
    required this.cajaId,
    required this.montoInicial,
    required this.abiertaPorUsuarioId,
    required this.fechaApertura,
    required this.estado,
  });

  factory SesionCaja.fromJson(Map<String, dynamic> json) => SesionCaja(
        id: json['id'] as String,
        cajaId: json['cajaId'] as String,
        montoInicial: (json['montoInicial'] as num).toDouble(),
        abiertaPorUsuarioId: json['abiertaPorUsuarioId'] as String,
        fechaApertura: DateTime.parse(json['fechaApertura'] as String),
        estado: EstadoSesionCaja.desdeValor(json['estado'] as int),
      );

  final String id;
  final String cajaId;
  final double montoInicial;
  final String abiertaPorUsuarioId;
  final DateTime fechaApertura;
  final EstadoSesionCaja estado;
}
