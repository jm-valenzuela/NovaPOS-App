/// Espejo de ClienteResumen (BuscarClientesQuery/BuscarClientePorRutQuery en el backend).
class ClienteResumen {
  const ClienteResumen({required this.id, required this.rut, required this.nombre, required this.email, required this.telefono});

  factory ClienteResumen.fromJson(Map<String, dynamic> json) => ClienteResumen(
        id: json['id'] as String,
        rut: json['rut'] as String?,
        nombre: json['nombre'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
      );

  final String id;
  final String? rut;
  final String nombre;
  final String? email;
  final String? telefono;
}
