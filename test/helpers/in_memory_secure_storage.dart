import 'package:novapos_app/core/storage/secure_storage.dart';

/// Fake de SecureStorage para tests — un Map en memoria, nada de canales
/// de plataforma. Usar vía ProviderScope(overrides: [tokenStorageProvider
/// .overrideWithValue(TokenStorage(InMemorySecureStorage()))]).
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _valores = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _valores.remove(key);
    } else {
      _valores[key] = value;
    }
  }

  @override
  Future<String?> read({required String key}) async => _valores[key];

  @override
  Future<void> delete({required String key}) async => _valores.remove(key);
}
