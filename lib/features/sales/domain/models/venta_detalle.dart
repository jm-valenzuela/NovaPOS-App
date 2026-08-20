import 'linea_impresion.dart';
import 'resumen_venta.dart';

/// Espejo de LineaVentaDetalle en el backend (ver ObtenerVentaQuery) — Cantidad/PrecioUnitario null en una línea libre (ej. mano de obra de una Orden de Trabajo), que no tiene Variante ni precio unitario, solo un Monto ya fijo.
class LineaVentaDetalle {
  const LineaVentaDetalle({required this.descripcion, this.cantidad, this.precioUnitario, required this.subtotal});

  factory LineaVentaDetalle.fromJson(Map<String, dynamic> json) => LineaVentaDetalle(
        descripcion: json['descripcion'] as String,
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        precioUnitario: (json['precioUnitario'] as num?)?.toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  final String descripcion;
  final double? cantidad;
  final double? precioUnitario;
  final double subtotal;
}

/// Espejo de VentaDetalle en el backend — detalle de una Venta ya
/// confirmada, con los datos del DTE emitido (si lo hay), para
/// mostrar/reimprimir la Boleta o Factura más adelante sin depender de
/// que el frontend haya guardado el resultado de confirmarVenta en
/// memoria (ver CobrarOrdenTrabajoDialog, que solo tenía el ventaId).
class VentaDetalle {
  const VentaDetalle({
    required this.id,
    required this.neto,
    required this.iva,
    required this.total,
    required this.lineas,
    this.dteEmitidoId,
    this.tipoDocumentoEmitido,
    this.folio,
    this.rutEmisor,
    this.razonSocialEmisor,
    this.rutReceptor,
    this.razonSocialReceptor,
    this.giroReceptor,
    this.direccionReceptor,
    this.comunaReceptor,
    this.ciudadReceptor,
    this.ted,
    this.fechaEmision,
  });

  factory VentaDetalle.fromJson(Map<String, dynamic> json) => VentaDetalle(
        id: json['id'] as String,
        neto: (json['neto'] as num).toDouble(),
        iva: (json['iva'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        lineas: (json['lineas'] as List<dynamic>).map((l) => LineaVentaDetalle.fromJson(l as Map<String, dynamic>)).toList(),
        dteEmitidoId: json['dteEmitidoId'] as String?,
        tipoDocumentoEmitido: json['tipoDocumentoEmitido'] as int?,
        folio: json['folio'] as int?,
        rutEmisor: json['rutEmisor'] as String?,
        razonSocialEmisor: json['razonSocialEmisor'] as String?,
        rutReceptor: json['rutReceptor'] as String?,
        razonSocialReceptor: json['razonSocialReceptor'] as String?,
        giroReceptor: json['giroReceptor'] as String?,
        direccionReceptor: json['direccionReceptor'] as String?,
        comunaReceptor: json['comunaReceptor'] as String?,
        ciudadReceptor: json['ciudadReceptor'] as String?,
        ted: json['ted'] as String?,
        fechaEmision: json['fechaEmision'] != null ? DateTime.parse(json['fechaEmision'] as String).toLocal() : null,
      );

  final String id;
  final double neto;
  final double iva;
  final double total;
  final List<LineaVentaDetalle> lineas;

  final String? dteEmitidoId;

  /// Código SII: 39 = Boleta, 33 = Factura (ver TipoDocumento.valorApi).
  final int? tipoDocumentoEmitido;
  final int? folio;
  final String? rutEmisor;
  final String? razonSocialEmisor;
  final String? rutReceptor;
  final String? razonSocialReceptor;
  final String? giroReceptor;
  final String? direccionReceptor;
  final String? comunaReceptor;
  final String? ciudadReceptor;
  final String? ted;
  final DateTime? fechaEmision;

  bool get tieneDte => dteEmitidoId != null;

  String get etiquetaDocumento => tipoDocumentoEmitido == 33 ? 'Factura' : 'Boleta';

  /// Para reusar imprimirBoletaFactura (ver representacion_impresa_venta.dart) sin que conozca este modelo.
  ResumenVenta get resumen => ResumenVenta(
        neto: neto,
        iva: iva,
        total: total,
        dteEmitidoId: dteEmitidoId,
        tipoDocumentoEmitido: tipoDocumentoEmitido,
        folio: folio,
        rutEmisor: rutEmisor,
        razonSocialEmisor: razonSocialEmisor,
        rutReceptor: rutReceptor,
        razonSocialReceptor: razonSocialReceptor,
        giroReceptor: giroReceptor,
        direccionReceptor: direccionReceptor,
        comunaReceptor: comunaReceptor,
        ciudadReceptor: ciudadReceptor,
        ted: ted,
        fechaEmision: fechaEmision,
      );

  List<LineaImpresion> get lineasImpresion => lineas
      .map((l) => LineaImpresion(descripcion: l.descripcion, cantidad: l.cantidad, subtotal: l.subtotal, precioUnitario: l.precioUnitario))
      .toList();
}
