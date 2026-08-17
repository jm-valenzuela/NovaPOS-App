import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../../core/utils/pdf_fonts.dart';

class ItemOferta {
  const ItemOferta({
    required this.nombreProducto,
    required this.sku,
    required this.precioVenta,
    this.precioOferta,
    this.etiquetaPromocion,
  });

  final String nombreProducto;
  final String sku;
  final double precioVenta;

  /// No nulo solo cuando la promoción es un precio de oferta literal — en
  /// ese caso el afiche destaca "antes/ahora". Para volumen o grupo (2x1,
  /// 4x3, "Desde N uds. -X%") no hay un segundo precio, así que se destaca
  /// `etiquetaPromocion` en su lugar.
  final double? precioOferta;
  final String? etiquetaPromocion;
}

/// Genera un afiche tamaño carta horizontal — **una página completa por
/// Variante en promoción**, con el precio o la etiqueta ("2x1", "Desde 15
/// uds. -5%", etc.) en letra gigante, para que se note lo conveniente que
/// es (a pedido explícito: "que se note lo conveniente que es... de
/// tamaño grande, para que se haga notar"; luego "formato de impresion
/// horizontal"). Mismo patrón `Printing.layoutPdf` que
/// imprimirEtiquetaCodigoBarras/imprimirTicketCotizacion: no se guarda
/// ningún archivo, se entrega directo al diálogo nativo de impresión.
Future<void> imprimirAficheOfertas(List<ItemOferta> items) {
  return Printing.layoutPdf(
    name: 'Ofertas',
    format: PdfPageFormat.letter.landscape,
    onLayout: (pageFormat) async {
      final documento = pw.Document(theme: await PdfFonts.tema());
      for (final item in items) {
        documento.addPage(
          pw.Page(pageFormat: pageFormat, build: (pwContext) => _paginaOferta(item, pwContext)),
        );
      }
      return documento.save();
    },
  );
}

pw.Widget _paginaOferta(ItemOferta item, pw.Context context) {
  return pw.Center(
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          constraints: const pw.BoxConstraints(maxWidth: 680),
          child: pw.Text(
            item.nombreProducto,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 52, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(item.sku, style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey600)),
        pw.SizedBox(height: 28),
        if (item.precioOferta != null) ...[
          pw.Text(
            MonedaFormatter.formatear(item.precioVenta),
            style: const pw.TextStyle(fontSize: 24, decoration: pw.TextDecoration.lineThrough, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            MonedaFormatter.formatear(item.precioOferta!),
            style: pw.TextStyle(fontSize: 100, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
          ),
        ] else ...[
          pw.Text(
            MonedaFormatter.formatear(item.precioVenta),
            style: pw.TextStyle(fontSize: _tamanoEtiqueta(item.etiquetaPromocion ?? '', context), fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),
          _bloquePromocion(item.etiquetaPromocion ?? '', context),
        ],
      ],
    ),
  );
}

/// Tope de tamaño de letra para el precio y el badge de promoción (ver
/// _paginaOferta) — a pedido explícito, el precio debe verse del mismo
/// porte que la promoción, no chico al lado de esta. 64pt es el máximo que
/// entra en el alto disponible de una página carta horizontal (~468pt,
/// `PdfPageFormat.letter.landscape.availableHeight`) incluso en el peor
/// caso: título de Producto largo (2 líneas a 52pt) + precio + badge
/// apilados (ver test del presupuesto vertical).
const _tamanoMaximoEtiqueta = 64.0;
const _tamanoMinimoEtiqueta = 30.0;

/// Ancho útil del badge: `maxWidth` de _bloquePromocion menos su padding horizontal.
const _anchoDisponibleEtiqueta = 620.0 - 40.0 * 2;

/// Tamaño de letra que reutilizan tanto el precio como el badge — mide el
/// ancho REAL de la etiqueta con las métricas de Fira Sans Bold (la misma
/// fuente con la que se dibuja, ver [PdfFonts] — usar la Helvetica-Bold
/// base del PDF solo para medir disparaba el aviso "has no Unicode
/// support" en consola en cada afiche, y sus métricas ni siquiera
/// coinciden con la fuente real) en vez de adivinar por cantidad de
/// caracteres, que fallaba tanto por exceso como por defecto — ver
/// historial de este archivo — y solo angosta la letra lo mínimo
/// necesario para que la etiqueta más larga entre en el badge sin saltar
/// de línea. La mayoría de las etiquetas reales ("2x1", "2do al 20%
/// dto.") caben directo al tope de 64pt; solo las más largas ("Desde 15
/// uds. -5%") bajan un poco.
double _tamanoEtiqueta(String etiqueta, pw.Context context) {
  final fuente = PdfFonts.bold.getFont(context);
  var tamano = _tamanoMaximoEtiqueta;
  while (tamano > _tamanoMinimoEtiqueta && fuente.stringMetrics(etiqueta).width * tamano > _anchoDisponibleEtiqueta) {
    tamano -= 2;
  }
  return tamano;
}

pw.Widget _bloquePromocion(String etiqueta, pw.Context context) {
  return pw.Container(
    constraints: const pw.BoxConstraints(maxWidth: 620),
    padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
    decoration: pw.BoxDecoration(color: PdfColors.green700, borderRadius: pw.BorderRadius.circular(20)),
    child: pw.Text(
      etiqueta,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: _tamanoEtiqueta(etiqueta, context), fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    ),
  );
}
