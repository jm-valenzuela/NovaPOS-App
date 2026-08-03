/// Espejo de BodegaVentaResumen (ObtenerBodegaDeVentaQuery en el backend).
class BodegaVenta {
  const BodegaVenta({required this.bodegaId, required this.nombreBodega});

  factory BodegaVenta.fromJson(Map<String, dynamic> json) => BodegaVenta(
        bodegaId: json['bodegaId'] as String,
        nombreBodega: json['nombreBodega'] as String,
      );

  final String bodegaId;
  final String nombreBodega;
}
