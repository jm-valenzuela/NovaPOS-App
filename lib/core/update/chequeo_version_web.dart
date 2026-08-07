// ignore_for_file: avoid_web_libraries_in_flutter
// Uso deliberado: este archivo solo se compila bajo `dart.library.html` (ver
// chequeo_version.dart), mismo patrón condicional web/stub que ya usa
// registrar_impresion_web_web.dart para el resto de la app.
import 'dart:html' as html;

/// "Firma" de la versión actualmente publicada en el servidor — se usa
/// el contenido de flutter_service_worker.js (Flutter lo regenera en
/// cada `flutter build web` con los hashes reales de los assets del
/// build), no version.json (que solo cambia si se bumpea el pubspec a
/// mano, algo que no pasa en cada deploy). No se registra este Service
/// Worker (ver web/index.html — causaba fallas silenciosas de
/// flutter_secure_storage), pero el archivo igual se genera y se sirve
/// como cualquier asset estático, así que sirve acá solo como huella de
/// "qué build está publicado ahora mismo", sin activar su lógica de cache.
Future<String?> obtenerFirmaVersionServida() async {
  try {
    final url = 'flutter_service_worker.js?_=${DateTime.now().millisecondsSinceEpoch}';
    final request = await html.HttpRequest.request(
      url,
      method: 'GET',
      requestHeaders: {'Cache-Control': 'no-cache'},
    );
    return request.responseText;
  } catch (_) {
    return null;
  }
}

void recargarPagina() => html.window.location.reload();
