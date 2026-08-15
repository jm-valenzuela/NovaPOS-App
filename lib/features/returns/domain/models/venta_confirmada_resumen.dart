/// Espejo de VentaConfirmadaResumen — fila liviana para elegir la Venta a
/// devolver (ver DevolucionVentaScreen), mismo criterio que
/// CotizacionResumen para "rescatar cotización".
class VentaConfirmadaResumen {
  const VentaConfirmadaResumen({
    required this.ventaId,
    required this.fechaConfirmacion,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.total,
    required this.cantidadLineas,
  });

  factory VentaConfirmadaResumen.fromJson(Map<String, dynamic> json) => VentaConfirmadaResumen(
        ventaId: json['ventaId'] as String,
        fechaConfirmacion: DateTime.parse(json['fechaConfirmacion'] as String),
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        total: (json['total'] as num).toDouble(),
        cantidadLineas: json['cantidadLineas'] as int,
      );

  final String ventaId;
  final DateTime fechaConfirmacion;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final double total;
  final int cantidadLineas;
}
