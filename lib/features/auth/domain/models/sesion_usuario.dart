/// Con qué Usuario y en qué Empresa está la sesión actual — para
/// mostrarlo en la UI (ver HomeScreen). Se completa desde el login
/// (AutenticacionResult) y se persiste en TokenStorage para sobrevivir
/// un reinicio de la app, ya que restaurar una sesión guardada no vuelve
/// a llamar a /auth/login.
class SesionUsuario {
  const SesionUsuario({
    required this.nombreCompleto,
    required this.email,
    required this.empresaRazonSocial,
    this.permisos = const [],
  });

  final String nombreCompleto;
  final String email;
  final String empresaRazonSocial;

  /// Códigos de permiso (ej. "sales.descuentos.autorizar") decodificados
  /// del Access Token actual — ver jwt_permisos.dart. Solo para
  /// mostrar/ocultar UI, la autorización real la hace el backend.
  final List<String> permisos;

  bool tienePermiso(String codigo) => permisos.contains(codigo);
}
