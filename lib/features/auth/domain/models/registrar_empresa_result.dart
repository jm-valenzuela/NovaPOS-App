/// Respuesta de POST /empresas (AprovisionarEmpresaResult en el backend).
class RegistrarEmpresaResult {
  const RegistrarEmpresaResult({
    required this.empresaId,
    required this.sucursalId,
    required this.cajaId,
    required this.usuarioAdministradorId,
  });

  factory RegistrarEmpresaResult.fromJson(Map<String, dynamic> json) => RegistrarEmpresaResult(
        empresaId: json['empresaId'] as String,
        sucursalId: json['sucursalId'] as String,
        cajaId: json['cajaId'] as String,
        usuarioAdministradorId: json['usuarioAdministradorId'] as String,
      );

  final String empresaId;
  final String sucursalId;
  final String cajaId;
  final String usuarioAdministradorId;
}

/// Espejo de ModalidadEmpresa en NovaPOS.Domain.Tenancy — el backend
/// espera el nombre del enum como string ("SaaS" u "OnPremise").
enum ModalidadEmpresa {
  saaS('SaaS'),
  onPremise('OnPremise');

  const ModalidadEmpresa(this.valorApi);

  final String valorApi;
}
