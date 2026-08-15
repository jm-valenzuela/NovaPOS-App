/// Espejo de TipoMovimientoCaja en NovaPOS.Domain.Cash.
enum TipoMovimientoCaja {
  ventaEfectivo(0),
  retiro(1),
  ventaTarjetaDebito(2),
  ventaTarjetaCredito(3),
  ventaCredito(4),
  devolucionEfectivo(5),
  ventaNotaCredito(6);

  const TipoMovimientoCaja(this.valorApi);

  final int valorApi;

  static TipoMovimientoCaja desdeValor(int valor) =>
      TipoMovimientoCaja.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoMovimientoCaja.ventaEfectivo);

  String get etiqueta => switch (this) {
        TipoMovimientoCaja.ventaEfectivo => 'Venta en efectivo',
        TipoMovimientoCaja.retiro => 'Retiro',
        TipoMovimientoCaja.ventaTarjetaDebito => 'Venta con Tarjeta Débito',
        TipoMovimientoCaja.ventaTarjetaCredito => 'Venta con Tarjeta Crédito',
        TipoMovimientoCaja.ventaCredito => 'Venta a Crédito',
        TipoMovimientoCaja.devolucionEfectivo => 'Devolución reembolsada',
        TipoMovimientoCaja.ventaNotaCredito => 'Venta con Nota de Crédito',
      };

  /// Solo el Retiro, las Ventas en efectivo y las Devoluciones reembolsadas
  /// mueven el efectivo físico de la Caja — Tarjeta/Crédito/Nota de Crédito
  /// son detalle informativo del arqueo (ver ObtenerResumenCierreQueryHandler
  /// en el backend).
  bool get afectaElEfectivo => this == ventaEfectivo || this == retiro || this == devolucionEfectivo;

  /// Las Devoluciones reembolsadas restan el efectivo, igual que un Retiro —
  /// el resto de los movimientos con afectaElEfectivo suman.
  bool get restaElEfectivo => this == retiro || this == devolucionEfectivo;
}

/// Espejo de MovimientoCajaResumen — una fila de la lista de movimientos del
/// resumen de cierre (Ventas en efectivo confirmadas + Retiros autorizados).
class MovimientoCaja {
  const MovimientoCaja({
    required this.tipo,
    required this.referenciaId,
    required this.monto,
    required this.detalle,
    required this.fecha,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) => MovimientoCaja(
        tipo: TipoMovimientoCaja.desdeValor(json['tipo'] as int),
        referenciaId: json['referenciaId'] as String,
        monto: (json['monto'] as num).toDouble(),
        detalle: json['detalle'] as String?,
        fecha: DateTime.parse(json['fecha'] as String),
      );

  final TipoMovimientoCaja tipo;
  final String referenciaId;
  final double monto;
  final String? detalle;
  final DateTime fecha;
}

/// Espejo del resultado de ObtenerResumenCierreQuery — preview en vivo
/// (montos calculados al vuelo) antes de cerrar, o el historial congelado
/// una vez que la Sesión ya está Cerrada (cerrada == true).
class ResumenCierreCaja {
  const ResumenCierreCaja({
    required this.sesionCajaId,
    required this.cajaId,
    required this.montoInicial,
    required this.totalVentasEfectivo,
    required this.totalVentasTarjetaDebito,
    required this.totalVentasTarjetaCredito,
    required this.totalVentasCredito,
    this.totalVentasNotaCredito = 0,
    required this.totalRetiros,
    this.totalDevolucionesEfectivo = 0,
    required this.montoEsperado,
    required this.montoContado,
    required this.diferencia,
    required this.cerrada,
    required this.movimientos,
  });

  factory ResumenCierreCaja.fromJson(Map<String, dynamic> json) => ResumenCierreCaja(
        sesionCajaId: json['sesionCajaId'] as String,
        cajaId: json['cajaId'] as String,
        montoInicial: (json['montoInicial'] as num).toDouble(),
        totalVentasEfectivo: (json['totalVentasEfectivo'] as num).toDouble(),
        totalVentasTarjetaDebito: (json['totalVentasTarjetaDebito'] as num).toDouble(),
        totalVentasTarjetaCredito: (json['totalVentasTarjetaCredito'] as num).toDouble(),
        totalVentasCredito: (json['totalVentasCredito'] as num).toDouble(),
        totalVentasNotaCredito: (json['totalVentasNotaCredito'] as num?)?.toDouble() ?? 0,
        totalRetiros: (json['totalRetiros'] as num).toDouble(),
        totalDevolucionesEfectivo: (json['totalDevolucionesEfectivo'] as num?)?.toDouble() ?? 0,
        montoEsperado: (json['montoEsperado'] as num).toDouble(),
        montoContado: (json['montoContado'] as num?)?.toDouble(),
        diferencia: (json['diferencia'] as num?)?.toDouble(),
        cerrada: json['cerrada'] as bool,
        movimientos: (json['movimientos'] as List<dynamic>)
            .map((m) => MovimientoCaja.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  final String sesionCajaId;
  final String cajaId;
  final double montoInicial;
  final double totalVentasEfectivo;
  final double totalVentasTarjetaDebito;
  final double totalVentasTarjetaCredito;
  final double totalVentasCredito;

  /// Informativo — la Nota de Crédito no es efectivo real, mismo criterio que Tarjeta/Crédito.
  final double totalVentasNotaCredito;
  final double totalRetiros;

  /// Devoluciones reembolsadas en efectivo desde esta Sesión — sí resta el efectivo real, igual que un Retiro.
  final double totalDevolucionesEfectivo;
  final double montoEsperado;
  final double? montoContado;
  final double? diferencia;
  final bool cerrada;
  final List<MovimientoCaja> movimientos;
}
