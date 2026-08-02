import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstracción sobre el almacenamiento seguro del SO — permite que
/// TokenStorage (y cualquier otra cosa que guarde datos sensibles más
/// adelante) se pruebe sin depender del canal de plataforma real de
/// flutter_secure_storage, que no existe en el entorno de `flutter test`
/// (las llamadas quedan colgadas para siempre, no lanzan ni resuelven).
abstract class SecureStorage {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureStorage {
  FlutterSecureStorageAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String? value}) => _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
