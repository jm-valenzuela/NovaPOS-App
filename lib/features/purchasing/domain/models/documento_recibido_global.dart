import 'purchasing_enums.dart';

/// Espejo de DocumentoRecibidoGlobalResumen — mercadería ligada a Orden de
/// Compra y Facturas Internas mezcladas, a través de todos los Proveedores
/// (pantalla global "Documentos Recibidos", reemplaza tener que entrar
/// Proveedor por Proveedor a pedido explícito del usuario).
class DocumentoRecibidoGlobal {
  const DocumentoRecibidoGlobal({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.proveedorRut,
    required this.ordenCompraId,
    required this.tipoDocumento,
    required this.folio,
    required this.rutEmisor,
    required this.montoTotal,
    required this.formaPago,
    required this.fechaEmision,
    required this.categoria,
    required this.rutaArchivoRespaldo,
  });

  factory DocumentoRecibidoGlobal.fromJson(Map<String, dynamic> json) => DocumentoRecibidoGlobal(
        id: json['id'] as String,
        proveedorId: json['proveedorId'] as String,
        proveedorNombre: json['proveedorNombre'] as String,
        proveedorRut: json['proveedorRut'] as String,
        ordenCompraId: json['ordenCompraId'] as String?,
        tipoDocumento: TipoDocumentoRecibido.desdeValor(json['tipoDocumento'] as int),
        folio: json['folio'] as int,
        rutEmisor: json['rutEmisor'] as String,
        montoTotal: (json['montoTotal'] as num).toDouble(),
        formaPago: FormaPago.desdeValor(json['formaPago'] as int),
        fechaEmision: DateTime.parse(json['fechaEmision'] as String),
        categoria: json['categoria'] == null ? null : CategoriaDocumentoRecibido.desdeValor(json['categoria'] as int),
        rutaArchivoRespaldo: json['rutaArchivoRespaldo'] as String?,
      );

  final String id;
  final String proveedorId;
  final String proveedorNombre;
  final String proveedorRut;
  final String? ordenCompraId;
  final TipoDocumentoRecibido tipoDocumento;
  final int folio;
  final String rutEmisor;
  final double montoTotal;
  final FormaPago formaPago;
  final DateTime fechaEmision;

  /// Solo cuando ordenCompraId es null (Factura Interna) — ver CategoriaDocumentoRecibido.
  final CategoriaDocumentoRecibido? categoria;

  final String? rutaArchivoRespaldo;
}
