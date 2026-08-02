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

  Future<void> guardar({
    required String accessToken,
    required DateTime accessTokenExpira,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _accessTokenExpiraKey, value: accessTokenExpira.toIso8601String()),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> obtenerAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> obtenerRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> obtenerAccessTokenExpira() async {
    final valor = await _storage.read(key: _accessTokenExpiraKey);
    return valor == null ? null : DateTime.tryParse(valor);
  }

  Future<void> limpiar() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiraKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
