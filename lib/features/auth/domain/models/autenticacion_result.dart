/// Respuesta de POST /auth/login y POST /auth/refresh — mismo shape en
/// ambos (AutenticacionResponse en AuthController.cs).
class AutenticacionResult {
  const AutenticacionResult({
    required this.accessToken,
    required this.accessTokenExpira,
    required this.refreshToken,
  });

  factory AutenticacionResult.fromJson(Map<String, dynamic> json) => AutenticacionResult(
        accessToken: json['accessToken'] as String,
        accessTokenExpira: DateTime.parse(json['accessTokenExpira'] as String),
        refreshToken: json['refreshToken'] as String,
      );

  final String accessToken;
  final DateTime accessTokenExpira;
  final String refreshToken;
}
