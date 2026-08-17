/// Espejo de ClienteCobranzaResumen en el backend (ListarCobranzaQuery) —
/// una fila del listado global de Cobranzas: TODOS los Clientes con Cupo
/// de Crédito asignado (tengan o no saldo pendiente ahora mismo), ya
/// viene ordenado del servidor (más atrasado primero).
class ClienteCobranza {
  const ClienteCobranza({
    required this.clienteId,
    required this.nombre,
    required this.rut,
    required this.cupoCredito,
    required this.plazoPagoId,
    required this.saldoTotal,
    required this.saldoVencido,
    required this.saldoPorVencer,
    required this.diasAtraso,
  });

  factory ClienteCobranza.fromJson(Map<String, dynamic> json) => ClienteCobranza(
        clienteId: json['clienteId'] as String,
        nombre: json['nombre'] as String,
        rut: json['rut'] as String?,
        cupoCredito: (json['cupoCredito'] as num).toDouble(),
        plazoPagoId: json['plazoPagoId'] as String?,
        saldoTotal: (json['saldoTotal'] as num).toDouble(),
        saldoVencido: (json['saldoVencido'] as num).toDouble(),
        saldoPorVencer: (json['saldoPorVencer'] as num).toDouble(),
        diasAtraso: json['diasAtraso'] as int,
      );

  final String clienteId;
  final String nombre;
  final String? rut;
  final double cupoCredito;
  final String? plazoPagoId;
  final double saldoTotal;
  final double saldoVencido;
  final double saldoPorVencer;
  final int diasAtraso;

  double get cupoDisponible => cupoCredito - saldoTotal;

  bool get sinDeudaVigente => saldoTotal <= 0;

  bool get estaVencido => saldoVencido > 0;
}
