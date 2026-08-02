import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'auth_exception.dart';

/// Adjunta el Access Token a cada request y, si el backend responde 401
/// (token vencido), intenta refrescarlo UNA vez con el Refresh Token y
/// reintenta la request original — igual que haría un cliente web con
/// cookies de sesión, pero explícito porque acá viajamos el token a mano.
///
/// Usa un Dio "pelado" (sin este mismo interceptor) para la llamada a
/// /auth/refresh — si usara el Dio principal, un refresh fallido
/// dispararía este mismo interceptor de nuevo sobre la llamada de
/// refresh, en un loop.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final Dio _dioSinInterceptor = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  bool _refrescando = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.obtenerAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final esNoAutorizado = err.response?.statusCode == 401;
    final yaReintentado = err.requestOptions.extra['reintentadoTrasRefresh'] == true;

    if (!esNoAutorizado || yaReintentado || _refrescando) {
      handler.next(err);
      return;
    }

    _refrescando = true;
    try {
      final refreshToken = await _tokenStorage.obtenerRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.limpiar();
        handler.reject(err);
        return;
      }

      final respuesta = await _dioSinInterceptor.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      await _tokenStorage.guardar(
        accessToken: respuesta.data['accessToken'] as String,
        accessTokenExpira: DateTime.parse(respuesta.data['accessTokenExpira'] as String),
        refreshToken: respuesta.data['refreshToken'] as String,
      );

      final requestOptions = err.requestOptions;
      requestOptions.extra['reintentadoTrasRefresh'] = true;
      requestOptions.headers['Authorization'] = 'Bearer ${respuesta.data['accessToken']}';

      final reintento = await _dioSinInterceptor.fetch(requestOptions);
      handler.resolve(reintento);
    } on DioException {
      // El Refresh Token también venció/fue revocado — no hay sesión que salvar.
      await _tokenStorage.limpiar();
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: AuthException('La sesión expiró. Inicia sesión nuevamente.'),
      ));
    } finally {
      _refrescando = false;
    }
  }
}
