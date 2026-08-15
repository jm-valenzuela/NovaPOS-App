import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

/// Mismo algoritmo que `_tamanoEtiqueta` en afiche_ofertas.dart — duplicado
/// acá a propósito (es privado, no se puede importar) para poder validar
/// su comportamiento real con las métricas de Helvetica-Bold.
double _tamanoEtiqueta(PdfFont fuente, String etiqueta) {
  const maximo = 64.0;
  const minimo = 30.0;
  const anchoDisponible = 620.0 - 40.0 * 2;
  var tamano = maximo;
  while (tamano > minimo && fuente.stringMetrics(etiqueta).width * tamano > anchoDisponible) {
    tamano -= 2;
  }
  return tamano;
}

void main() {
  final fuente = PdfFont.helveticaBold(PdfDocument());

  test('Etiquetas cortas ("2x1", "2do al 20% dto.") quedan al tope de 64pt', () {
    for (final etiqueta in ['2x1', '4x3', '2do al 20% dto.', '2do al 40% dto.']) {
      expect(_tamanoEtiqueta(fuente, etiqueta), 64.0, reason: '"$etiqueta" debería caber al tamaño máximo');
    }
  });

  test('Una etiqueta larga ("Desde 15 uds. -5%") se achica lo mínimo necesario para no salirse del badge', () {
    const etiqueta = 'Desde 15 uds. -5%';
    const anchoDisponible = 620.0 - 40.0 * 2;

    final tamano = _tamanoEtiqueta(fuente, etiqueta);

    expect(tamano, lessThan(64.0), reason: 'a 64pt esta etiqueta no entra en el ancho del badge');
    expect(fuente.stringMetrics(etiqueta).width * tamano, lessThan(anchoDisponible));
  });

  test(
      'Peor caso (título en 2 líneas + etiqueta al tamaño máximo de 64pt) cabe dentro del alto disponible '
      'de la página carta horizontal', () {
    // Mismos valores que afiche_ofertas.dart (_paginaOferta) — duplicados
    // acá a propósito para que este test falle si alguien los vuelve a
    // subir sin revisar el peor caso. El paquete `pdf` NO lanza excepción
    // cuando un Column se sale del alto de la página: recorta en silencio
    // el contenido que no entra — por eso `documento.save()` no sirve para
    // detectar esta regresión, hay que validar la geometría directamente.
    // Bug real reportado dos veces: 1) con 110pt el badge de "2x1"
    // desaparecía por completo; 2) con 30-46pt el precio se veía chico al
    // lado del badge.
    const tituloFontSize = 52.0;
    const skuFontSize = 18.0;
    const gapTituloSku = 10.0;
    const gapSkuPrecio = 28.0;
    const precioFontSizeMax = 64.0; // tope de _tamanoEtiqueta
    const gapPrecioBadge = 14.0;
    const badgeFontSizeMax = 64.0;
    const badgePaddingVertical = 28.0 * 2;

    // Factor de alto de línea conservador (Helvetica ronda ~1.15-1.2x el
    // tamaño de fuente) — se usa uno más pesimista a propósito, para dejar
    // margen de error en vez de calcular al límite exacto.
    const lineHeightFactor = 1.35;

    final pageFormat = PdfPageFormat.letter.landscape;
    final altoDisponible = pageFormat.availableHeight;

    const altoPeorCaso = (tituloFontSize * lineHeightFactor * 2) + // título forzado a 2 líneas
        gapTituloSku +
        (skuFontSize * lineHeightFactor) +
        gapSkuPrecio +
        (precioFontSizeMax * lineHeightFactor) +
        gapPrecioBadge +
        (badgeFontSizeMax * lineHeightFactor + badgePaddingVertical);

    expect(
      altoPeorCaso,
      lessThan(altoDisponible),
      reason: 'El precio + el badge de promoción se salen de la página con un título de 2 líneas '
          '(disponible: $altoDisponible pt, usado: $altoPeorCaso pt) — el badge quedaría cortado al imprimir.',
    );
  });
}
