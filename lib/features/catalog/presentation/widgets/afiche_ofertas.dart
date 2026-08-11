import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';

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
      final documento = pw.Document();
      for (final item in items) {
        documento.addPage(
          pw.Page(pageFormat: pageFormat, build: (pwContext) => _paginaOferta(item)),
        );
      }
      return documento.save();
    },
  );
}

pw.Widget _paginaOferta(ItemOferta item) {
  return pw.Center(
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          item.nombreProducto,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(item.sku, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
        pw.SizedBox(height: 48),
        if (item.precioOferta != null) ...[
          pw.Text(
            MonedaFormatter.formatear(item.precioVenta),
            style: const pw.TextStyle(fontSize: 24, decoration: pw.TextDecoration.lineThrough, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            MonedaFormatter.formatear(item.precioOferta!),
            style: pw.TextStyle(fontSize: 100, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
          ),
        ] else ...[
          pw.Text(
            MonedaFormatter.formatear(item.precioVenta),
            style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 32),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            decoration: pw.BoxDecoration(color: PdfColors.green700, borderRadius: pw.BorderRadius.circular(16)),
            child: pw.Text(
              item.etiquetaPromocion ?? '',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 44, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
        ],
      ],
    ),
  );
}
