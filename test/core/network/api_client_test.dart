import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novapos_app/core/network/api_client.dart';
import 'package:novapos_app/core/network/auth_exception.dart';

void main() {
  final requestOptions = RequestOptions(path: '/cotizaciones');

  group('ApiClient.lanzarError', () {
    test('con mensaje del backend, usa ese mensaje tal cual', () {
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {'error': 'Ya existe un Cliente con el RUT 76.123.456-0'},
        ),
      );

      expect(
        () => ApiClient.lanzarError(dioException),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Ya existe un Cliente con el RUT 76.123.456-0',
        )),
      );
    });

    test('sin backend disponible (connectionError), muestra un mensaje entendible por quien opera el sistema, sin jerga técnica', () {
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        error: 'The XMLHttpRequest onError callback was called. This typically indicates an error on the network layer.',
        message: 'The connection errored: The XMLHttpRequest onError callback was called.',
      );

      expect(
        () => ApiClient.lanzarError(dioException),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
        )),
      );
    });

    test('sin backend disponible, el mensaje NO incluye el detalle técnico de Dio', () {
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        error: 'XMLHttpRequest onError callback',
      );

      expect(
        () => ApiClient.lanzarError(dioException),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          allOf(isNot(contains('connectionError')), isNot(contains('XMLHttpRequest'))),
        )),
      );
    });

    test('AuthException se relanza tal cual, sin envolver en ApiException', () {
      final authException = AuthException('Sesión expirada');
      final dioException = DioException(requestOptions: requestOptions, error: authException);

      expect(() => ApiClient.lanzarError(dioException), throwsA(same(authException)));
    });
  });
}
