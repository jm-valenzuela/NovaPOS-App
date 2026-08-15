import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de conexión al backend NovaPOS.Api.
///
/// El emulador de Android no puede resolver "localhost" como el propio
/// equipo host — Android reserva 10.0.2.2 como alias del host para eso.
/// Windows desktop y Chrome (web) sí resuelven localhost directamente.
/// Para apuntar a un servidor real (no localhost), pasar
/// --dart-define=API_BASE_URL=https://api.novapos.cl al compilar/correr.
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:6453/api/v1';
    return 'http://localhost:6453/api/v1';
  }

  /// Host sin el prefijo '/api/v1' — para armar la URL de archivos
  /// estáticos (imágenes, respaldos), que se sirven fuera de la Api REST.
  static String get origin => baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
}
