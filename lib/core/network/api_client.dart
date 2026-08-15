import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'auth_exception.dart';
import 'auth_interceptor.dart';

/// Envoltorio único de Dio para todo el llamado a NovaPOS.Api — cada
/// feature (auth, ventas, inventario, etc.) inyecta esto en su propio
/// *Api en vez de instanciar Dio por su cuenta, para compartir el mismo
/// interceptor de sesión (token + refresh automático).
class ApiClient {
  ApiClient(TokenStorage tokenStorage)
      : dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        ))
          ..interceptors.add(AuthInterceptor(tokenStorage));

  final Dio dio;

  /// Traduce un DioException a una excepción propia con el mensaje real
  /// que devuelve el backend (`{"error": "..."}`) — si no hay uno (falla
  /// de red/timeout/CORS/parseo), usa un mensaje genérico apto para quien
  /// esté operando el sistema (sin jerga técnica de Dio/XMLHttpRequest); el
  /// detalle técnico (tipo + statusCode si lo hay) se manda aparte a la
  /// consola de diagnóstico, no al mensaje que ve el usuario.
  static Never lanzarError(DioException e) {
    if (e.error is AuthException) throw e.error as AuthException;

    final data = e.response?.data;
    final mensaje = (data is Map && data['error'] is String)
        ? data['error'] as String
        : 'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.';

    if (data is! Map || data['error'] is! String) {
      developer.log(
        '${e.type.name}${e.response?.statusCode != null ? ' HTTP ${e.response?.statusCode}' : ''} ${e.message ?? e.error ?? ''}',
        name: 'ApiClient',
        error: e,
      );
    }

    throw ApiException(mensaje, statusCode: e.response?.statusCode);
  }
}
