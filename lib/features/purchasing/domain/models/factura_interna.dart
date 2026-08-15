import 'purchasing_enums.dart';

/// Espejo de FacturaInternaResumen — DocumentoRecibido sin OrdenCompraId, a
/// través de todos los Proveedores (ver ListarFacturasInternasQuery en el
/// backend). A diferencia de DocumentoRecibido (por Proveedor), esta trae
/// el Nombre/Rut del Proveedor ya resuelto para el listado global.
class FacturaInterna {
  const FacturaInterna({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.proveedorRut,
    required this.tipoDocumento,
    required this.folio,
    required this.rutEmisor,
    required this.montoTotal,
    required this.formaPago,
    required this.fechaEmision,
    required this.categoria,
    required this.rutaArchivoRespaldo,
  });

  factory FacturaInterna.fromJson(Map<String, dynamic> json) => FacturaInterna(
        id: json['id'] as String,
        proveedorId: json['proveedorId'] as String,
        proveedorNombre: json['proveedorNombre'] as String,
        proveedorRut: json['proveedorRut'] as String,
        tipoDocumento: TipoDocumentoRecibido.desdeValor(json['tipoDocumento'] as int),
        folio: json['folio'] as int,
        rutEmisor: json['rutEmisor'] as String,
        montoTotal: (json['montoTotal'] as num).toDouble(),
        formaPago: FormaPago.desdeValor(json['formaPago'] as int),
        fechaEmision: DateTime.parse(json['fechaEmision'] as String),
        categoria: CategoriaDocumentoRecibido.desdeValor(json['categoria'] as int),
        rutaArchivoRespaldo: json['rutaArchivoRespaldo'] as String?,
      );

  final String id;
  final String proveedorId;
  final String proveedorNombre;
  final String proveedorRut;
  final TipoDocumentoRecibido tipoDocumento;
  final int folio;
  final String rutEmisor;
  final double montoTotal;
  final FormaPago formaPago;
  final DateTime fechaEmision;
  final CategoriaDocumentoRecibido categoria;
  final String? rutaArchivoRespaldo;
}
