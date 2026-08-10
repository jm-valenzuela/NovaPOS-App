/// Espejo de ProveedorPorPagarResumen en el backend (ListarCuentasPorPagarQuery) —
/// una fila del listado global de Cuentas por Pagar, ya viene ordenado del
/// servidor (más atrasado primero).
class ProveedorPorPagar {
  const ProveedorPorPagar({
    required this.proveedorId,
    required this.nombre,
    required this.rut,
    required this.saldoTotal,
    required this.saldoVencido,
    required this.saldoPorVencer,
    required this.diasAtraso,
  });

  factory ProveedorPorPagar.fromJson(Map<String, dynamic> json) => ProveedorPorPagar(
        proveedorId: json['proveedorId'] as String,
        nombre: json['nombre'] as String,
        rut: json['rut'] as String?,
        saldoTotal: (json['saldoTotal'] as num).toDouble(),
        saldoVencido: (json['saldoVencido'] as num).toDouble(),
        saldoPorVencer: (json['saldoPorVencer'] as num).toDouble(),
        diasAtraso: json['diasAtraso'] as int,
      );

  final String proveedorId;
  final String nombre;
  final String? rut;
  final double saldoTotal;
  final double saldoVencido;
  final double saldoPorVencer;
  final int diasAtraso;

  /// "Al día" no es un estado alcanzable acá — este listado solo trae
  /// Proveedores con SaldoTotal > 0 (ver ListarCuentasPorPagarQuery), así
  /// que siempre es Vencido o Por vencer.
  bool get estaVencido => saldoVencido > 0;
}
