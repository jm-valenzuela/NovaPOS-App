/// Espejo de CajaResumen (ListarCajasQuery en el backend).
class CajaResumen {
  const CajaResumen({
    required this.cajaId,
    required this.codigoCaja,
    required this.nombreCaja,
    required this.sucursalId,
    required this.nombreSucursal,
  });

  factory CajaResumen.fromJson(Map<String, dynamic> json) => CajaResumen(
        cajaId: json['cajaId'] as String,
        codigoCaja: json['codigoCaja'] as String,
        nombreCaja: json['nombreCaja'] as String,
        sucursalId: json['sucursalId'] as String,
        nombreSucursal: json['nombreSucursal'] as String,
      );

  final String cajaId;
  final String codigoCaja;
  final String nombreCaja;
  final String sucursalId;
  final String nombreSucursal;
}
