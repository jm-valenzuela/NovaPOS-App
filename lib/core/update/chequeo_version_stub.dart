/// No-op en plataformas no-web (Android/Windows) — ahí la app se
/// actualiza reinstalando/reemplazando el binario, no hace falta
/// chequear una versión servida por HTTP.
Future<String?> obtenerFirmaVersionServida() async => null;

void recargarPagina() {}
