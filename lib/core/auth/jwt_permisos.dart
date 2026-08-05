import 'dart:convert';

/// Decodifica el claim "permiso" del payload de un Access Token JWT — solo
/// para mostrar/ocultar UI (ej. el ítem "Descuentos pendientes" en Home),
/// nunca para autorizar de verdad: la autorización real ya la hace el
/// backend en cada endpoint vía [Authorize(Policy = "...")], esto es
/// puramente cosmético. Por eso no hace falta validar la firma acá.
List<String> permisosDesdeJwt(String accessToken) {
  final partes = accessToken.split('.');
  if (partes.length != 3) return const [];

  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final permiso = json['permiso'];
    if (permiso == null) return const [];
    if (permiso is List) return permiso.map((p) => p.toString()).toList();
    return [permiso.toString()];
  } catch (_) {
    return const [];
  }
}
