import 'secure_storage.dart';

/// Guarda el Access Token y Refresh Token en almacenamiento seguro del
/// SO (Keychain en macOS/iOS, Keystore en Android, DPAPI en Windows) —
/// nunca en SharedPreferences plano, son credenciales de sesión.
class TokenStorage {
  TokenStorage(this._storage);

  final SecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _accessTokenExpiraKey = 'access_token_expira';
  static const _refreshTokenKey = 'refresh_token';
  static const _nombreCompletoKey = 'sesion_nombre_completo';
  static const _emailKey = 'sesion_email';
  static const _empresaRazonSocialKey = 'sesion_empresa_razon_social';

  /// Escribe secuencial, NUNCA con Future.wait: en flutter_secure_storage_web,
  /// la primera escritura en un origen nuevo (sin clave de cifrado AES-GCM
  /// todavía en localStorage) genera y persiste una — si dos escrituras
  /// corren en paralelo, cada una genera SU PROPIA clave al no ver
  /// todavía la de la otra, y la que pierde la carrera queda con un
  /// valor cifrado con una clave que ya no está guardada en ningún lado
  /// (falla al desencriptar con "OperationError" más tarde). Ver
  /// flutter_secure_storage_web/lib/flutter_secure_storage_web.dart,
  /// _getEncryptionKey.
  Future<void> guardar({
    required String accessToken,
    required DateTime accessTokenExpira,
    required String refreshToken,
    String? nombreCompleto,
    String? email,
    String? empresaRazonSocial,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _accessTokenExpiraKey, value: accessTokenExpira.toIso8601String());
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    // Solo el login manda estos 3 — el refresh los deja null (ver
    // AutenticacionResult en el backend), así que no se sobrescriben acá.
    if (nombreCompleto != null) await _storage.write(key: _nombreCompletoKey, value: nombreCompleto);
    if (email != null) await _storage.write(key: _emailKey, value: email);
    if (empresaRazonSocial != null) await _storage.write(key: _empresaRazonSocialKey, value: empresaRazonSocial);
  }

  Future<String?> obtenerAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> obtenerRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> obtenerAccessTokenExpira() async {
    final valor = await _storage.read(key: _accessTokenExpiraKey);
    return valor == null ? null : DateTime.tryParse(valor);
  }

  Future<String?> obtenerNombreCompleto() => _storage.read(key: _nombreCompletoKey);

  Future<String?> obtenerEmail() => _storage.read(key: _emailKey);

  Future<String?> obtenerEmpresaRazonSocial() => _storage.read(key: _empresaRazonSocialKey);

  Future<void> limpiar() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiraKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _nombreCompletoKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _empresaRazonSocialKey),
    ]);
  }
}
