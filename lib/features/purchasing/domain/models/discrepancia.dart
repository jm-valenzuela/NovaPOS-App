import 'purchasing_enums.dart';

/// Espejo de DiscrepanciaDocumentoRecibidoResumen — diferencia entre lo
/// negociado en la Orden de Compra y el monto real del Documento
/// Recibido, generada automáticamente por el backend (nunca a mano).
class Discrepancia {
  const Discrepancia({
    required this.id,
    required this.documentoRecibidoId,
    required this.ordenCompraId,
    required this.proveedorId,
    required this.montoDocumento,
    required this.montoNegociado,
    required this.diferencia,
    required this.estado,
    required this.motivoResolucion,
    required this.fechaDeteccion,
    required this.fechaResolucion,
  });

  factory Discrepancia.fromJson(Map<String, dynamic> json) => Discrepancia(
        id: json['id'] as String,
        documentoRecibidoId: json['documentoRecibidoId'] as String,
        ordenCompraId: json['ordenCompraId'] as String,
        proveedorId: json['proveedorId'] as String,
        montoDocumento: (json['montoDocumento'] as num).toDouble(),
        montoNegociado: (json['montoNegociado'] as num).toDouble(),
        diferencia: (json['diferencia'] as num).toDouble(),
        estado: EstadoDiscrepancia.desdeValor(json['estado'] as int),
        motivoResolucion: json['motivoResolucion'] as String?,
        fechaDeteccion: DateTime.parse(json['fechaDeteccion'] as String),
        fechaResolucion: json['fechaResolucion'] == null ? null : DateTime.parse(json['fechaResolucion'] as String),
      );

  final String id;
  final String documentoRecibidoId;
  final String ordenCompraId;
  final String proveedorId;
  final double montoDocumento;
  final double montoNegociado;
  final double diferencia;
  final EstadoDiscrepancia estado;
  final String? motivoResolucion;
  final DateTime fechaDeteccion;
  final DateTime? fechaResolucion;
}
