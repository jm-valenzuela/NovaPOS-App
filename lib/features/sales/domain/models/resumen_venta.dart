/// Espejo de la respuesta de confirmar una Venta (Venta.DesglosarIva en el
/// backend) — los precios de NovaPOS son IVA incluido, así que Neto/Iva se
/// derivan de Total, nunca al revés.
///
/// Los campos desde [dteEmitidoId] en adelante vienen de VentasController.
/// Confirmar cuando el backend logró emitir el DTE en NovaPOS.Dte (ver
/// ConfirmarVentaCommandHandler.ObtenerDteAsync) — todos null si la Venta
/// no generó DTE (ej. es a Crédito) o si NovaPOS.Dte no respondió a tiempo.
class ResumenVenta {
  const ResumenVenta({
    required this.neto,
    required this.iva,
    required this.total,
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

  factory ResumenVenta.fromJson(Map<String, dynamic> json) => ResumenVenta(
        neto: (json['neto'] as num).toDouble(),
        iva: (json['iva'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
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

  /// Mismo cálculo que Venta.DesglosarIva en el backend — usado para el
  /// desglose en vivo del carrito, antes de que exista una Venta real en
  /// el servidor (ver LineaCarrito: el carrito es puro estado de cliente).
  factory ResumenVenta.calcular(double total) {
    const tasaIva = 0.19;
    final neto = (total / (1 + tasaIva)).roundToDouble();
    return ResumenVenta(neto: neto, iva: total - neto, total: total);
  }

  final double neto;
  final double iva;
  final double total;

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

  /// Timbre Electrónico (TED) firmado con la llave privada del CAF — se
  /// imprime como texto plano en el ticket, no como código PDF417 (ver
  /// representacion_impresa_venta.dart), así que esta "representación
  /// impresa" no es válida ante el SII, solo un resumen informativo.
  final String? ted;
  final DateTime? fechaEmision;

  /// true si NovaPOS.Dte emitió un DTE real para esta Venta — controla si
  /// se ofrece el botón "Imprimir Boleta/Factura" tras cobrar.
  bool get tieneDte => dteEmitidoId != null;
}
