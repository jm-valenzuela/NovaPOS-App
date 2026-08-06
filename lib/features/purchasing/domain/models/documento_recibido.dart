import 'purchasing_enums.dart';

/// Espejo de DocumentoRecibidoResumen — la Boleta/Factura real que un
/// Proveedor emitió, distinta del Total estimado al negociar la Orden.
class DocumentoRecibido {
  const DocumentoRecibido({
    required this.id,
    required this.ordenCompraId,
    required this.tipoDocumento,
    required this.folio,
    required this.rutEmisor,
    required this.montoTotal,
    required this.formaPago,
    required this.fechaEmision,
  });

  factory DocumentoRecibido.fromJson(Map<String, dynamic> json) => DocumentoRecibido(
        id: json['id'] as String,
        ordenCompraId: json['ordenCompraId'] as String?,
        tipoDocumento: TipoDocumentoRecibido.desdeValor(json['tipoDocumento'] as int),
        folio: json['folio'] as int,
        rutEmisor: json['rutEmisor'] as String,
        montoTotal: (json['montoTotal'] as num).toDouble(),
        formaPago: FormaPago.desdeValor(json['formaPago'] as int),
        fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      );

  final String id;
  final String? ordenCompraId;
  final TipoDocumentoRecibido tipoDocumento;
  final int folio;
  final String rutEmisor;
  final double montoTotal;
  final FormaPago formaPago;
  final DateTime fechaEmision;
}
