import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/moneda_formatter.dart';

/// EAN-13 (13 dígitos numéricos con dígito verificador válido, mismo
/// algoritmo que GeneradorCodigoBarras en el backend) para los códigos
/// generados automáticamente; Code128 para cualquier otro valor — soporta
/// texto libre, por si el código de barras se cargó a mano (el campo nunca
/// tuvo validación de formato) y no es un EAN-13 real, lo que además haría
/// fallar la codificación como EAN-13 en vez de solo verse "raro".
bw.Barcode _simbologiaPara(String codigo) => _esEan13Valido(codigo) ? bw.Barcode.ean13() : bw.Barcode.code128();

bool _esEan13Valido(String codigo) {
  if (codigo.length != 13 || !RegExp(r'^[0-9]{13}$').hasMatch(codigo)) return false;

  var suma = 0;
  for (var i = 0; i < 12; i++) {
    final digito = int.parse(codigo[i]);
    suma += i % 2 == 0 ? digito : digito * 3;
  }
  final resto = suma % 10;
  final esperado = resto == 0 ? 0 : 10 - resto;
  return int.parse(codigo[12]) == esperado;
}

/// Previsualización en pantalla de la etiqueta — mismos datos que
/// imprimirEtiquetaCodigoBarras, pero como widget de Flutter en vez de PDF.
class VistaPreviaEtiqueta extends StatelessWidget {
  const VistaPreviaEtiqueta({
    super.key,
    required this.nombre,
    required this.sku,
    required this.precioVenta,
    required this.codigoBarras,
    this.mostrarPrecio = true,
  });

  final String nombre;
  final String sku;
  final double precioVenta;
  final String codigoBarras;

  /// Algunas Empresas no quieren el precio impreso en la etiqueta (ej. para
  /// que el vendedor lo consulte en el sistema en vez de en la góndola) —
  /// ver imprimirEtiquetaCodigoBarras.
  final bool mostrarPrecio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(sku, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          bw.BarcodeWidget(
            key: const Key('vistaPreviaEtiquetaBarcode'),
            data: codigoBarras,
            barcode: _simbologiaPara(codigoBarras),
            width: 200,
            height: 70,
            drawText: true,
          ),
          if (mostrarPrecio) ...[
            const SizedBox(height: 4),
            Text(MonedaFormatter.formatear(precioVenta), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ],
      ),
    );
  }
}

/// Abre el diálogo de impresión del sistema operativo con una etiqueta de
/// 8x5cm (tamaño típico de etiqueta autoadhesiva de góndola) — Nombre,
/// Sku, código de barras y, opcionalmente, Precio (algunas Empresas no
/// quieren el precio impreso — ver `mostrarPrecio`). No se guarda ningún
/// archivo: `printing` entrega el PDF directo al diálogo de impresión/vista
/// previa nativo.
Future<void> imprimirEtiquetaCodigoBarras({
  required String nombre,
  required String sku,
  required double precioVenta,
  required String codigoBarras,
  bool mostrarPrecio = true,
}) {
  const formato = PdfPageFormat(8 * PdfPageFormat.cm, 5 * PdfPageFormat.cm, marginAll: 4 * PdfPageFormat.mm);
  final simbologia = _simbologiaPara(codigoBarras);

  return Printing.layoutPdf(
    name: 'Etiqueta-$sku',
    format: formato,
    onLayout: (pageFormat) async {
      final documento = pw.Document();
      documento.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pwContext) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(nombre, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(sku, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),
              // pw.BarcodeWidget dibuja las barras directo en el PDF (sin pasar
              // por SVG, cuyo parser en el paquete `pdf` solo soporta un
              // subconjunto limitado) — mismo criterio que BarcodeWidget de
              // Flutter en la previsualización de pantalla.
              pw.BarcodeWidget(data: codigoBarras, barcode: simbologia, width: 60 * PdfPageFormat.mm, height: 20 * PdfPageFormat.mm),
              if (mostrarPrecio) ...[
                pw.SizedBox(height: 4),
                pw.Text(MonedaFormatter.formatear(precioVenta), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ],
          ),
        ),
      );
      return documento.save();
    },
  );
}
