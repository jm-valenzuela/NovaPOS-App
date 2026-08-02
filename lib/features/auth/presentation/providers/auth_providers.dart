import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/models/registrar_empresa_result.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authApiProvider), ref.watch(tokenStorageProvider));
});

enum AuthStatus { desconocido, autenticado, noAutenticado }

class AuthState {
  const AuthState({this.status = AuthStatus.desconocido, this.cargando = false, this.error});

  final AuthStatus status;
  final bool cargando;
  final String? error;

  AuthState copyWith({AuthStatus? status, bool? cargando, String? error, bool limpiarError = false}) {
    return AuthState(
      status: status ?? this.status,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Estado global de sesión — GoRouter lo observa (ver app_router.dart)
/// para redirigir automáticamente entre Login y el resto de la app.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    _verificarSesionAlIniciar();
  }

  final AuthRepository _repository;

  Future<void> _verificarSesionAlIniciar() async {
    try {
      final activa = await _repository.haySesionActiva();
      state = state.copyWith(status: activa ? AuthStatus.autenticado : AuthStatus.noAutenticado);
    } catch (_) {
      // Si el almacenamiento seguro no está disponible (o falla por
      // cualquier motivo), fail-closed hacia Login — nunca dejar la app
      // colgada en el splash ni asumir sesión válida sin poder verificarla.
      state = state.copyWith(status: AuthStatus.noAutenticado);
    }
  }

  Future<void> login({required String rut, required String email, required String password}) async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      await _repository.login(rut: rut, email: email, password: password);
      state = state.copyWith(cargando: false, status: AuthStatus.autenticado);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(status: AuthStatus.noAutenticado);
  }

  void limpiarError() => state = state.copyWith(limpiarError: true);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Estado propio de la pantalla de Registro de Empresa — deliberadamente
/// separado de AuthState: registrar no deja sesión iniciada (ver
/// AuthRepositoryImpl.registrarEmpresa), es un flujo previo a Login.
class RegistroEmpresaState {
  const RegistroEmpresaState({this.cargando = false, this.error, this.resultado});

  final bool cargando;
  final String? error;
  final RegistrarEmpresaResult? resultado;

  RegistroEmpresaState copyWith({bool? cargando, String? error, RegistrarEmpresaResult? resultado, bool limpiarError = false}) {
    return RegistroEmpresaState(
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      resultado: resultado ?? this.resultado,
    );
  }
}

class RegistroEmpresaController extends StateNotifier<RegistroEmpresaState> {
  RegistroEmpresaController(this._repository) : super(const RegistroEmpresaState());

  final AuthRepository _repository;

  Future<void> registrar({
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
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final resultado = await _repository.registrarEmpresa(
        razonSocial: razonSocial,
        rut: rut,
        giroComercial: giroComercial,
        emailEmpresa: emailEmpresa,
        modalidadEmpresa: modalidadEmpresa,
        nombreSucursalInicial: nombreSucursalInicial,
        nombreAdministrador: nombreAdministrador,
        emailAdministrador: emailAdministrador,
        passwordAdministrador: passwordAdministrador,
      );
      state = state.copyWith(cargando: false, resultado: resultado);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final registroEmpresaControllerProvider =
    StateNotifierProvider.autoDispose<RegistroEmpresaController, RegistroEmpresaState>((ref) {
  return RegistroEmpresaController(ref.watch(authRepositoryProvider));
});
