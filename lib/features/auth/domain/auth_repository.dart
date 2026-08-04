import 'models/registrar_empresa_result.dart';
import 'models/sesion_usuario.dart';

/// Contrato de la capa de dominio para autenticación/registro — la
/// presentación depende de esto, no de AuthApi/Dio directamente (mismo
/// principio de inversión de dependencias que IVentaRepository en el backend).
abstract class AuthRepository {
  Future<SesionUsuario> login({required String rut, required String email, required String password});

  /// Con qué Usuario/Empresa hay sesión activa ahora mismo — leído de lo
  /// guardado en el último login (ver TokenStorage), sin llamar al
  /// backend. Null si no hay datos de sesión guardados.
  Future<SesionUsuario?> obtenerSesionActual();

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
  });

  Future<void> logout();

  /// true si hay un Access Token guardado y no vencido, o un Refresh
  /// Token con el que se pueda renovar — usado al abrir la app para
  /// decidir si mandar a Login o directo al Home.
  Future<bool> haySesionActiva();
}
