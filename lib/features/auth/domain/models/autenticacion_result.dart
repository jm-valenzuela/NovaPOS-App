/// Respuesta de POST /auth/login y POST /auth/refresh — mismo shape en
/// ambos (AutenticacionResponse en AuthController.cs). Los últimos 3
/// campos solo vienen completos en la respuesta de login — el backend
/// los deja null en el refresh (ver AutenticacionResult.cs), así que acá
/// son nullable a propósito.
class AutenticacionResult {
  const AutenticacionResult({
    required this.accessToken,
    required this.accessTokenExpira,
    required this.refreshToken,
    this.nombreCompleto,
    this.email,
    this.empresaRazonSocial,
  });

  factory AutenticacionResult.fromJson(Map<String, dynamic> json) => AutenticacionResult(
        accessToken: json['accessToken'] as String,
        accessTokenExpira: DateTime.parse(json['accessTokenExpira'] as String),
        refreshToken: json['refreshToken'] as String,
        nombreCompleto: json['nombreCompleto'] as String?,
        email: json['email'] as String?,
        empresaRazonSocial: json['empresaRazonSocial'] as String?,
      );

  final String accessToken;
  final DateTime accessTokenExpira;
  final String refreshToken;
  final String? nombreCompleto;
  final String? email;
  final String? empresaRazonSocial;
}
