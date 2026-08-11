import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';

class ItemOferta {
  const ItemOferta({
    required this.nombreProducto,
    required this.sku,
    required this.precioVenta,
    required this.precioOferta,
  });

  final String nombreProducto;
  final String sku;
  final double precioVenta;
  final double precioOferta;
}

/// Genera un afiche A4 con una tarjeta por Variante en oferta — Nombre,
/// Sku, precio normal tachado y precio de oferta destacado — para pegar en
/// la góndola o repartir como volante. Mismo patrón `Printing.layoutPdf`
/// que imprimirEtiquetaCodigoBarras/imprimirTicketCotizacion: no se guarda
/// ningún archivo, se entrega directo al diálogo nativo de impresión.
Future<void> imprimirAficheOfertas(List<ItemOferta> items) {
  return Printing.layoutPdf(
    name: 'Ofertas',
    format: PdfPageFormat.a4,
    onLayout: (pageFormat) async {
      final documento = pw.Document();
      documento.addPage(
        pw.MultiPage(
          pageFormat: pageFormat.copyWith(
            marginLeft: 16 * PdfPageFormat.mm,
            marginRight: 16 * PdfPageFormat.mm,
            marginTop: 16 * PdfPageFormat.mm,
            marginBottom: 16 * PdfPageFormat.mm,
          ),
          build: (pwContext) => [
            pw.Header(
              text: 'Ofertas vigentes',
              textStyle: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final item in items) _tarjetaOferta(item)],
            ),
          ],
        ),
      );
      return documento.save();
    },
  );
}

pw.Widget _tarjetaOferta(ItemOferta item) {
  return pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8), borderRadius: pw.BorderRadius.circular(6)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(item.nombreProducto, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12), maxLines: 2),
        pw.Text(item.sku, style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 6),
        pw.Text(
          MonedaFormatter.formatear(item.precioVenta),
          style: const pw.TextStyle(fontSize: 10, decoration: pw.TextDecoration.lineThrough),
        ),
        pw.Text(
          MonedaFormatter.formatear(item.precioOferta),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
        ),
      ],
    ),
  );
}
