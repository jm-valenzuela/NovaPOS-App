import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/cotizacion.dart';
import '../../domain/models/resumen_venta.dart';

/// Abre el diálogo de impresión del sistema operativo con el detalle de
/// una Cotización guardada (Cliente, líneas, Subtotal/IVA/Total) en
/// formato ticket de 8cm — igual que imprimirEtiquetaCodigoBarras, no se
/// guarda ningún archivo, `printing` entrega el PDF directo al diálogo
/// nativo. Deja explícito que no es un documento tributario, para que el
/// Cliente no lo confunda con una Boleta/Factura.
Future<void> imprimirTicketCotizacion(CotizacionDetalle cotizacion) {
  final resumen = ResumenVenta.calcular(cotizacion.total);

  return Printing.layoutPdf(
    name: 'Cotizacion-${cotizacion.ventaId.substring(0, 8)}',
    format: const PdfPageFormat(8 * PdfPageFormat.cm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
    onLayout: (pageFormat) async {
      final documento = pw.Document();
      documento.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pwContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('COTIZACIÓN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.SizedBox(height: 4),
              pw.Text('Cliente: ${cotizacion.clienteNombre}', style: const pw.TextStyle(fontSize: 9)),
              if (cotizacion.clienteRut != null) pw.Text('RUT: ${cotizacion.clienteRut}', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              for (final linea in cotizacion.lineas) ...[
                pw.Text(linea.nombreProducto, style: const pw.TextStyle(fontSize: 9)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${_formatearCantidad(linea.cantidad)} x ${MonedaFormatter.formatear(linea.precioUnitario)}',
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
              pw.SizedBox(height: 10),
              pw.Text(
                'Cotización sin valor tributario, sujeta a stock y precio vigente al momento de la compra.',
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

pw.Widget _filaResumen(String etiqueta, double monto, {bool negrita = false}) {
  final estilo = pw.TextStyle(fontSize: negrita ? 11 : 9, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal);
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [pw.Text(etiqueta, style: estilo), pw.Text(MonedaFormatter.formatear(monto), style: estilo)],
  );
}

String _formatearCantidad(double cantidad) => cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();
