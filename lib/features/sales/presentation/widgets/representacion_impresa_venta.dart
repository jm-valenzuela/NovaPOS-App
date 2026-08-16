import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/linea_carrito.dart';
import '../../domain/models/resumen_venta.dart';

/// Abre el diálogo de impresión del sistema operativo con la
/// representación impresa de la Boleta/Factura recién emitida — mismo
/// patrón que imprimirTicketCotizacion (Printing.layoutPdf, sin guardar
/// ningún archivo). Solo se debe llamar con un [resumen] que tenga
/// [ResumenVenta.tieneDte] en true (el llamador ya lo valida antes de
/// ofrecer el botón). No es un facsímil oficial del SII: el TED se
/// imprime como texto plano, no como código PDF417, así que este ticket
/// no reemplaza la representación normada — ver aviso al pie.
Future<void> imprimirBoletaFactura(ResumenVenta resumen, List<LineaCarrito> lineas) {
  final formatoFecha = DateFormat('dd-MM-yyyy HH:mm');
  final esFactura = resumen.tipoDocumentoEmitido == 33;
  final etiquetaDocumento = esFactura ? 'FACTURA ELECTRÓNICA' : 'BOLETA ELECTRÓNICA';

  return Printing.layoutPdf(
    name: '$etiquetaDocumento-${resumen.folio}',
    format: const PdfPageFormat(8 * PdfPageFormat.cm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
    onLayout: (pageFormat) async {
      final documento = pw.Document();
      documento.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pwContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text(etiquetaDocumento, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13))),
              pw.Center(child: pw.Text('Folio ${resumen.folio}', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 6),
              pw.Divider(),
              if (resumen.razonSocialEmisor != null)
                pw.Text(resumen.razonSocialEmisor!, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (resumen.rutEmisor != null) pw.Text('RUT: ${resumen.rutEmisor}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Text('Señor(a): ${resumen.razonSocialReceptor ?? 'Cliente Genérico'}', style: const pw.TextStyle(fontSize: 8)),
              if (resumen.rutReceptor != null) pw.Text('RUT: ${resumen.rutReceptor}', style: const pw.TextStyle(fontSize: 8)),
              if (resumen.giroReceptor != null) pw.Text('Giro: ${resumen.giroReceptor}', style: const pw.TextStyle(fontSize: 8)),
              if (resumen.direccionReceptor != null)
                pw.Text('Dirección: ${resumen.direccionReceptor}', style: const pw.TextStyle(fontSize: 8)),
              if (resumen.comunaReceptor != null || resumen.ciudadReceptor != null)
                pw.Text('${resumen.comunaReceptor ?? ''} ${resumen.ciudadReceptor ?? ''}'.trim(), style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Divider(),
              for (final linea in lineas) ...[
                pw.Text(linea.producto.nombreProducto, style: const pw.TextStyle(fontSize: 9)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${_formatearCantidad(linea.cantidad)} x ${MonedaFormatter.formatear(linea.subtotal / linea.cantidad)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(MonedaFormatter.formatear(linea.subtotal), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 4),
              ],
              pw.Divider(),
              _filaResumen('Subtotal', resumen.neto),
              _filaResumen('IVA (19%)', resumen.iva),
              pw.SizedBox(height: 2),
              _filaResumen('Total', resumen.total, negrita: true),
              pw.SizedBox(height: 6),
              if (resumen.fechaEmision != null)
                pw.Text('Fecha emisión: ${formatoFecha.format(resumen.fechaEmision!)}', style: const pw.TextStyle(fontSize: 8)),
              if (resumen.ted != null) ...[
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Text('Timbre Electrónico SII (TED)', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(resumen.ted!, style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
              ],
              pw.SizedBox(height: 8),
              pw.Text(
                'Timbre verificable ante el SII. Esta representación es informativa: no incluye el código PDF417 normado.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      );
      return documento.save();
    },
  );
}

pw.Widget _filaResumen(String etiqueta, double monto, {bool negrita = false}) {
  final estilo = pw.TextStyle(fontSize: negrita ? 11 : 9, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal);
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [pw.Text(etiqueta, style: estilo), pw.Text(MonedaFormatter.formatear(monto), style: estilo)],
  );
}

String _formatearCantidad(double cantidad) => cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();
