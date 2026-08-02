import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/models/registrar_empresa_result.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokenStorage);

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  @override
  Future<void> login({required String rut, required String email, required String password}) async {
    final resultado = await _api.login(rut: rut, email: email, password: password);
    await _tokenStorage.guardar(
      accessToken: resultado.accessToken,
      accessTokenExpira: resultado.accessTokenExpira,
      refreshToken: resultado.refreshToken,
    );
  }

  @override
  Future<RegistrarEmpresaResult> registrarEmpresa({
    required String razonSocial,
    required String rut,
    required String giroComercial,
    required String emailEmpresa,
    required ModalidadEmpresa modalidadEmpresa,
    required String nombreSucursalInicial,
    required String nombreAdministrador,
    required String emailAdministrador,
    required String passwordAdministrador,
  }) async {
    final resultado = await _api.registrarEmpresa(
      razonSocial: razonSocial,
      rut: rut,
      giroComercial: giroComercial,
      emailEmpresa: emailEmpresa,
      modalidadEmpresa: modalidadEmpresa.valorApi,
      nombreSucursalInicial: nombreSucursalInicial,
      nombreAdministrador: nombreAdministrador,
      emailAdministrador: emailAdministrador,
      passwordAdministrador: passwordAdministrador,
    );

    // Registrar la Empresa no deja sesión iniciada — el flujo real es
    // "registrar y luego hacer login" (mismo criterio que el backend:
    // EmpresasController no emite JWT, ver su comentario de diseño).
    return resultado;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.obtenerRefreshToken();
    if (refreshToken != null) {
      await _api.logout(refreshToken);
    }
    await _tokenStorage.limpiar();
  }

  @override
  Future<bool> haySesionActiva() async {
    final accessToken = await _tokenStorage.obtenerAccessToken();
    final refreshToken = await _tokenStorage.obtenerRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
