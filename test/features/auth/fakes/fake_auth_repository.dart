import 'package:novapos_app/features/auth/domain/auth_repository.dart';
import 'package:novapos_app/features/auth/domain/models/registrar_empresa_result.dart';

/// Fake de AuthRepository — deja registrado exactamente con qué
/// argumentos se llamó cada método, sin tocar Dio/HTTP real. Mismo
/// espíritu que los *RepositorioFalso del backend (NovaPOS.UnitTests).
class FakeAuthRepository implements AuthRepository {
  bool sesionActiva = false;
  String? errorAforzar;

  int vecesLoginLlamado = 0;
  String? ultimoRutLogin;
  String? ultimoEmailLogin;
  String? ultimoPasswordLogin;

  int vecesRegistrarLlamado = 0;
  String? ultimaRazonSocial;
  String? ultimoRutEmpresa;
  String? ultimoGiroComercial;
  String? ultimoEmailEmpresa;
  ModalidadEmpresa? ultimaModalidad;
  String? ultimoNombreSucursal;
  String? ultimoNombreAdministrador;
  String? ultimoEmailAdministrador;
  String? ultimoPasswordAdministrador;

  RegistrarEmpresaResult resultadoARetornar = const RegistrarEmpresaResult(
    empresaId: 'empresa-fake-id',
    sucursalId: 'sucursal-fake-id',
    cajaId: 'caja-fake-id',
    usuarioAdministradorId: 'usuario-fake-id',
  );

  @override
  Future<bool> haySesionActiva() async => sesionActiva;

  @override
  Future<void> login({required String rut, required String email, required String password}) async {
    vecesLoginLlamado++;
    ultimoRutLogin = rut;
    ultimoEmailLogin = email;
    ultimoPasswordLogin = password;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> logout() async {
    sesionActiva = false;
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
    vecesRegistrarLlamado++;
    ultimaRazonSocial = razonSocial;
    ultimoRutEmpresa = rut;
    ultimoGiroComercial = giroComercial;
    ultimoEmailEmpresa = emailEmpresa;
    ultimaModalidad = modalidadEmpresa;
    ultimoNombreSucursal = nombreSucursalInicial;
    ultimoNombreAdministrador = nombreAdministrador;
    ultimoEmailAdministrador = emailAdministrador;
    ultimoPasswordAdministrador = passwordAdministrador;

    if (errorAforzar != null) throw Exception(errorAforzar);
    return resultadoARetornar;
  }
}
