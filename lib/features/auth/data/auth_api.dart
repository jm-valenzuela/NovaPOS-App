import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/autenticacion_result.dart';
import '../domain/models/registrar_empresa_result.dart';

/// Llamadas HTTP crudas a los endpoints de autenticación/registro — sin
/// lógica de negocio ni de sesión, eso vive en AuthRepositoryImpl.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AutenticacionResult> login({
    required String rut,
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _client.dio.post('/auth/login', data: {
        'rut': rut,
        'email': email,
        'password': password,
      });
      return AutenticacionResult.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<AutenticacionResult> refrescar(String refreshToken) async {
    try {
      final respuesta = await _client.dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      return AutenticacionResult.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // El logout siempre "tiene éxito" del lado del cliente — la sesión
      // local se limpia igual aunque la llamada al servidor falle (ver
      // AuthRepositoryImpl.logout), mismo criterio que el backend (204
      // exista o no el token, ver AuthController.Logout).
    }
  }

  Future<RegistrarEmpresaResult> registrarEmpresa({
    required String razonSocial,
    required String rut,
    required String giroComercial,
    required String emailEmpresa,
    required String modalidadEmpresa,
    required String nombreSucursalInicial,
    required String nombreAdministrador,
    required String emailAdministrador,
    required String passwordAdministrador,
  }) async {
    try {
      final respuesta = await _client.dio.post('/empresas', data: {
        'razonSocial': razonSocial,
        'rut': rut,
        'giroComercial': giroComercial,
        'emailEmpresa': emailEmpresa,
        'modalidadEmpresa': modalidadEmpresa,
        'nombreSucursalInicial': nombreSucursalInicial,
        'nombreAdministrador': nombreAdministrador,
        'emailAdministrador': emailAdministrador,
        'passwordAdministrador': passwordAdministrador,
      });
      return RegistrarEmpresaResult.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
