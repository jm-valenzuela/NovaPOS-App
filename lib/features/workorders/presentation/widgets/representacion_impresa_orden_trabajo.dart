import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../../core/utils/pdf_fonts.dart';
import '../../domain/models/orden_trabajo.dart';

/// Comprobante de servicio de una Orden de Trabajo — NO es un documento
/// tributario (a diferencia de representacion_impresa_venta.dart, no
/// lleva Folio ni Timbre Electrónico): es el respaldo de qué se recibió,
/// qué se cotizó/aprobó por Ítem, y cuánto queda pendiente, para
/// entregarle una copia al Cliente o dejarla con el vehículo/equipo.
/// Mismo layout/tipografía que el resto de la app.
Future<void> imprimirOrdenTrabajo(OrdenTrabajoDetalle orden) {
  final formatoFecha = DateFormat('dd-MM-yyyy HH:mm');

  return Printing.layoutPdf(
    name: 'Orden-de-Trabajo-${orden.numero}',
    format: const PdfPageFormat(8 * PdfPageFormat.cm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
    onLayout: (pageFormat) async {
      final documento = pw.Document(theme: await PdfFonts.tema());
      documento.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pwContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('ORDEN DE TRABAJO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13))),
              pw.Center(child: pw.Text(orden.numero, style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Text('Señor(a): ${orden.clienteNombre}', style: const pw.TextStyle(fontSize: 9)),
              if (orden.clienteRut != null) pw.Text('RUT: ${orden.clienteRut}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Text('Estado: ${orden.estado.etiqueta}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Recibida: ${formatoFecha.format(orden.fechaRecepcion.toLocal())}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Text(orden.descripcion, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Text('Ítems', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              for (final item in orden.items) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(item.descripcion, style: const pw.TextStyle(fontSize: 9))),
                    pw.Text('[${item.estado.etiqueta}]', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
                for (final linea in item.lineas)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          linea.tipo == TipoLineaOrdenTrabajo.producto ? '${linea.descripcion} x${linea.cantidad?.toStringAsFixed(0)}' : linea.descripcion,
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ),
                      pw.Text(MonedaFormatter.formatear(linea.monto), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (item.motivoRechazo != null)
                  pw.Text('Motivo: ${item.motivoRechazo}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                if (item.montoTotal != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [pw.Text(MonedaFormatter.formatear(item.montoTotal!), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))],
                  ),
                pw.SizedBox(height: 6),
              ],
              pw.Divider(),
              if (orden.montoCotizado != null) _filaResumen('Total cotizado', MonedaFormatter.formatear(orden.montoCotizado!)),
              if (orden.montoAprobado != null) _filaResumen('Total aprobado', MonedaFormatter.formatear(orden.montoAprobado!)),
              if (orden.montoAnticipado != null) _filaResumen('Anticipos recibidos', '-${MonedaFormatter.formatear(orden.montoAnticipado!)}'),
              if (orden.saldoPendiente != null)
                _filaResumen('Saldo pendiente', MonedaFormatter.formatear(orden.saldoPendiente!), negrita: true),
              pw.SizedBox(height: 10),
              pw.Text(
                'Este comprobante no es una Boleta ni Factura Electrónica — es un respaldo del servicio recibido.',
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

pw.Widget _filaResumen(String etiqueta, String montoFormateado, {bool negrita = false}) {
  final estilo = pw.TextStyle(fontSize: negrita ? 11 : 9, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal);
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [pw.Text(etiqueta, style: estilo), pw.Text(montoFormateado, style: estilo)],
  );
}
