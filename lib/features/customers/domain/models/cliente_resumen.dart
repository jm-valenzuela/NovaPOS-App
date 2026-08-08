/// Espejo de ClienteResumen (BuscarClientesQuery/BuscarClientePorRutQuery en el backend).
class ClienteResumen {
  const ClienteResumen({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.cupoCredito = 0,
    this.plazoPagoId,
    this.giro,
    this.direccion,
    this.comuna,
    this.ciudad,
    this.estadoSolicitudCredito = 0,
  });

  factory ClienteResumen.fromJson(Map<String, dynamic> json) => ClienteResumen(
        id: json['id'] as String,
        rut: json['rut'] as String?,
        nombre: json['nombre'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
        cupoCredito: (json['cupoCredito'] as num?)?.toDouble() ?? 0,
        plazoPagoId: json['plazoPagoId'] as String?,
        giro: json['giro'] as String?,
        direccion: json['direccion'] as String?,
        comuna: json['comuna'] as String?,
        ciudad: json['ciudad'] as String?,
        estadoSolicitudCredito: json['estadoSolicitudCredito'] as int? ?? 0,
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

  /// Referencia al catálogo de Plazos de Pago (ver PlazoPago) — null significa vencimiento inmediato.
  final String? plazoPagoId;

  /// Datos del receptor exigidos por el SII para emitir una Factura (una
  /// Boleta no los necesita) — opcionales a nivel de dominio, ver
  /// Cliente.TieneDatosCompletosParaFactura en el backend.
  final String? giro;
  final String? direccion;
  final String? comuna;
  final String? ciudad;

  /// Espejo de EstadoSolicitudCredito en el backend: 0 SinSolicitar, 1
  /// Pendiente, 2 Autorizada, 3 Rechazada — entero crudo (no enum Dart)
  /// porque es el único lugar de la UI que lo necesita, mismo criterio
  /// que UnidadMedida antes de tener su propio enum dedicado.
  final int estadoSolicitudCredito;

  bool get tieneSolicitudCreditoPendiente => estadoSolicitudCredito == 1;
}
