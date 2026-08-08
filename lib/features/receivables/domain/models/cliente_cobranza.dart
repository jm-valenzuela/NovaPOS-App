/// Espejo de ClienteCobranzaResumen en el backend (ListarCobranzaQuery) —
/// una fila del listado global de Cobranzas, ya viene ordenado del
/// servidor (más atrasado primero).
class ClienteCobranza {
  const ClienteCobranza({
    required this.clienteId,
    required this.nombre,
    required this.rut,
    required this.saldoTotal,
    required this.saldoVencido,
    required this.saldoPorVencer,
    required this.diasAtraso,
  });

  factory ClienteCobranza.fromJson(Map<String, dynamic> json) => ClienteCobranza(
        clienteId: json['clienteId'] as String,
        nombre: json['nombre'] as String,
        rut: json['rut'] as String?,
        saldoTotal: (json['saldoTotal'] as num).toDouble(),
        saldoVencido: (json['saldoVencido'] as num).toDouble(),
        saldoPorVencer: (json['saldoPorVencer'] as num).toDouble(),
        diasAtraso: json['diasAtraso'] as int,
      );

  final String clienteId;
  final String nombre;
  final String? rut;
  final double saldoTotal;
  final double saldoVencido;
  final double saldoPorVencer;
  final int diasAtraso;

  /// "Al día" no es un estado alcanzable acá — este listado solo trae
  /// Clientes con SaldoTotal > 0 (ver ListarCobranzaQuery), así que
  /// siempre es Vencido o Por vencer.
  bool get estaVencido => saldoVencido > 0;
}
