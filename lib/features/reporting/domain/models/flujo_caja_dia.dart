/// Espejo de FlujoCajaDiaResumen en el backend (FlujoCajaQuery) — una fila
/// del reporte de flujo de caja para un día del rango consultado.
///
/// Real = efectivo que realmente entró/salió de caja ese día (Ventas/
/// Compras al Contado + Abonos). Proyectado = lo que se espera que
/// entre/salga según la FechaVencimiento de los Cargos pendientes — una
/// expectativa, no un hecho consumado (ver comentario del backend en
/// IReportingRepository.ObtenerFlujoCajaAsync).
class FlujoCajaDia {
  const FlujoCajaDia({
    required this.fecha,
    required this.entradaReal,
    required this.salidaReal,
    required this.flujoNetoReal,
    required this.entradaProyectada,
    required this.salidaProyectada,
    required this.flujoNetoProyectado,
  });

  factory FlujoCajaDia.fromJson(Map<String, dynamic> json) => FlujoCajaDia(
        fecha: DateTime.parse(json['fecha'] as String),
        entradaReal: (json['entradaReal'] as num).toDouble(),
        salidaReal: (json['salidaReal'] as num).toDouble(),
        flujoNetoReal: (json['flujoNetoReal'] as num).toDouble(),
        entradaProyectada: (json['entradaProyectada'] as num).toDouble(),
        salidaProyectada: (json['salidaProyectada'] as num).toDouble(),
        flujoNetoProyectado: (json['flujoNetoProyectado'] as num).toDouble(),
      );

  final DateTime fecha;
  final double entradaReal;
  final double salidaReal;
  final double flujoNetoReal;
  final double entradaProyectada;
  final double salidaProyectada;
  final double flujoNetoProyectado;
}
