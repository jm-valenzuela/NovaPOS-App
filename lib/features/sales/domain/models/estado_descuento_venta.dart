import 'venta_enums.dart';

/// Espejo de EstadoDescuentoVentaResumen (ObtenerEstadoDescuentoVentaQuery
/// en el backend) — el POS consulta esto mientras espera que alguien
/// autorice/rechace el descuento que el Cajero pidió.
class EstadoDescuentoVenta {
  const EstadoDescuentoVenta({
    required this.ventaId,
    required this.estado,
    required this.total,
    required this.subtotalLineas,
    required this.motivoRechazo,
  });

  factory EstadoDescuentoVenta.fromJson(Map<String, dynamic> json) => EstadoDescuentoVenta(
        ventaId: json['ventaId'] as String,
        estado: EstadoDescuentoGeneral.desdeValor(json['estadoDescuentoGeneral'] as int),
        total: (json['total'] as num).toDouble(),
        subtotalLineas: (json['subtotalLineas'] as num).toDouble(),
        motivoRechazo: json['motivoRechazoDescuento'] as String?,
      );

  final String ventaId;
  final EstadoDescuentoGeneral estado;
  final double total;
  final double subtotalLineas;
  final String? motivoRechazo;
}
