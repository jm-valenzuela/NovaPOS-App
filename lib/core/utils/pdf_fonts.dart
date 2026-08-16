import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Fuente Unicode real para los PDF generados en la app (tickets, etiquetas,
/// afiches) — sin esto, `pw.Document` usa Helvetica (fuente base del propio
/// formato PDF), que solo cubre WinAnsi y hace que `pdf` avise en consola
/// ("has no Unicode support") cada vez que se construye. Fira Sans tiene
/// cobertura Unicode amplia (diseñada por Mozilla para Firefox OS) y trae
/// archivos estáticos reales por peso (Regular/Bold) — a diferencia de la
/// mayoría de Google Fonts hoy, que son variables y no permiten un "bold"
/// real al incrustarse en un PDF (el paquete `pdf` no aplica ejes
/// variables, solo la instancia por defecto del archivo).
class PdfFonts {
  PdfFonts._();

  static pw.ThemeData? _tema;

  static Future<pw.ThemeData> tema() async {
    final cache = _tema;
    if (cache != null) return cache;

    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/FiraSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/FiraSans-Bold.ttf'));
    final tema = pw.ThemeData.withFont(base: regular, bold: bold);
    _tema = tema;
    return tema;
  }
}
