/// Espejo de ClienteResumen (BuscarClientesQuery/BuscarClientePorRutQuery en el backend).
class ClienteResumen {
  const ClienteResumen({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.cupoCredito = 0,
    this.plazoPagoDias = 0,
  });

  factory ClienteResumen.fromJson(Map<String, dynamic> json) => ClienteResumen(
        id: json['id'] as String,
        rut: json['rut'] as String?,
        nombre: json['nombre'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
        cupoCredito: (json['cupoCredito'] as num?)?.toDouble() ?? 0,
        plazoPagoDias: json['plazoPagoDias'] as int? ?? 0,
      );

  final String id;
  final String? rut;
  final String nombre;
  final String? email;
  final String? telefono;

  /// Presentes desde que ClienteResumen se extendió para la pantalla de
  /// mantención de Clientes — antes de eso el selector del POS no los
  /// necesitaba. Default 0 para no romper otros usos del modelo que no
  /// los pasan (ej. fixtures de test ya existentes).
  final double cupoCredito;
  final int plazoPagoDias;
}
