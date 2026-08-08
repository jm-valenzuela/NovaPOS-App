/// Espejo de CuotaPlazoPagoResumen (backend) — una cuota individual dentro de un PlazoPago.
class CuotaPlazoPago {
  const CuotaPlazoPago({required this.numeroCuota, required this.diasVencimiento});

  factory CuotaPlazoPago.fromJson(Map<String, dynamic> json) => CuotaPlazoPago(
        numeroCuota: json['numeroCuota'] as int,
        diasVencimiento: json['diasVencimiento'] as int,
      );

  final int numeroCuota;
  final int diasVencimiento;
}

/// Espejo de PlazoPagoResumen (ListarPlazosPagoQuery en el backend) — un
/// término de pago del catálogo de Proveedores (ej. "Contado", "30 días",
/// "30-60-90 días"). Catálogo separado del de Clientes a propósito — ver
/// NovaPOS.Domain.Purchasing.PlazoPago en el backend.
class PlazoPago {
  const PlazoPago({required this.id, required this.nombre, required this.activo, required this.cuotas});

  factory PlazoPago.fromJson(Map<String, dynamic> json) => PlazoPago(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool,
        cuotas: (json['cuotas'] as List<dynamic>).map((c) => CuotaPlazoPago.fromJson(c as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String nombre;
  final bool activo;
  final List<CuotaPlazoPago> cuotas;
}
