import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../../core/utils/pdf_fonts.dart';
import '../../domain/models/orden_trabajo.dart';

/// Comprobante interno de un Anticipo recién registrado — NO es un
/// documento tributario (no lleva Folio, Timbre Electrónico ni Total con
/// IVA desglosado, a diferencia de representacion_impresa_venta.dart):
/// el Anticipo no genera Boleta/Factura, solo un respaldo de que el
/// Cliente entregó ese dinero por adelantado (ver AnticipoOrdenTrabajo en
/// el backend). Mismo layout/tipografía que el resto de la app para que
/// no se vea como un ticket distinto.
Future<void> imprimirComprobanteAnticipo({
  required String numeroOrden,
  required String clienteNombre,
  required double monto,
  required MedioPagoAnticipo medioPago,
  required DateTime fecha,
}) {
  final formatoFecha = DateFormat('dd-MM-yyyy HH:mm');

  return Printing.layoutPdf(
    name: 'Comprobante-Anticipo-$numeroOrden',
    format: const PdfPageFormat(8 * PdfPageFormat.cm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
    onLayout: (pageFormat) async {
      final documento = pw.Document(theme: await PdfFonts.tema());
      documento.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pwContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('COMPROBANTE DE ANTICIPO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13))),
              pw.Center(child: pw.Text('Orden de Trabajo $numeroOrden', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Text('Señor(a): $clienteNombre', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Medio de pago', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(medioPago.etiqueta, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Monto recibido', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(MonedaFormatter.formatear(monto), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text('Fecha: ${formatoFecha.format(fecha)}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Este comprobante respalda un pago recibido por adelantado — no es una Boleta ni Factura Electrónica. '
                'El documento tributario correspondiente se emite al entregar la Orden de Trabajo.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      );
      return documento.save();
    },
  );
}
