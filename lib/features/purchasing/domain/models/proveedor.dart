/// Espejo de ProveedorResumen — a diferencia de ClienteResumen, el Rut
/// nunca es null (ver Proveedor.cs en el backend: siempre se sabe a
/// quién se le compró).
class ProveedorResumen {
  const ProveedorResumen({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.plazoPagoId,
  });

  factory ProveedorResumen.fromJson(Map<String, dynamic> json) => ProveedorResumen(
        id: json['id'] as String,
        rut: json['rut'] as String,
        nombre: json['nombre'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
        plazoPagoId: json['plazoPagoId'] as String?,
      );

  final String id;
  final String rut;
  final String nombre;
  final String? email;
  final String? telefono;

  /// Referencia al catálogo de Plazos de Pago (ver PlazoPago) — null significa vencimiento inmediato.
  final String? plazoPagoId;
}
