/// Lanzada cuando el backend responde 401/403, o cuando el refresh del
/// Access Token falla (Refresh Token vencido/revocado) — la capa de
/// presentación reacciona a esto cerrando la sesión y volviendo a Login.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Error de negocio devuelto por el backend con un mensaje explicable al
/// usuario (ej. "Ya existe un Cliente con el RUT...") — se distingue de
/// errores de red/infraestructura, que no tienen un mensaje útil para mostrar.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
