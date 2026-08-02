import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../storage/token_storage.dart';

/// Providers compartidos entre features — cada *Api de feature depende
/// de apiClientProvider, nunca instancia Dio por su cuenta (ver
/// ApiClient para el porqué: un solo interceptor de sesión para todos).
/// Los tests de widgets sobreescriben tokenStorageProvider con una
/// SecureStorage en memoria (ver test/helpers) — el canal de plataforma
/// real de flutter_secure_storage no existe bajo `flutter test`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(FlutterSecureStorageAdapter(const FlutterSecureStorage()));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});
