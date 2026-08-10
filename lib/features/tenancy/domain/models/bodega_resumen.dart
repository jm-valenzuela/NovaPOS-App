/// Espejo de TipoBodega en NovaPOS.Domain.Tenancy.
enum TipoBodega {
  venta(0),
  respaldo(1),
  transito(2);

  const TipoBodega(this.valorApi);

  final int valorApi;

  static TipoBodega desdeValor(int valor) => TipoBodega.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoBodega.venta);

  String get etiqueta => switch (this) {
        TipoBodega.venta => 'Venta',
        TipoBodega.respaldo => 'Respaldo',
        TipoBodega.transito => 'Tránsito',
      };
}

/// Espejo de BodegaResumen (ListarBodegasQuery) — a diferencia de
/// BodegaVenta, trae TODAS las Bodegas de la Empresa, no solo la de venta
/// de una Sucursal; usado por las pantallas de Inventario para elegir
/// entre Bodegas.
class BodegaResumen {
  const BodegaResumen({
    required this.bodegaId,
    required this.nombreBodega,
    required this.tipoBodega,
    required this.sucursalId,
    required this.nombreSucursal,
  });

  factory BodegaResumen.fromJson(Map<String, dynamic> json) => BodegaResumen(
        bodegaId: json['bodegaId'] as String,
        nombreBodega: json['nombreBodega'] as String,
        tipoBodega: TipoBodega.desdeValor(json['tipoBodega'] as int),
        sucursalId: json['sucursalId'] as String,
        nombreSucursal: json['nombreSucursal'] as String,
      );

  final String bodegaId;
  final String nombreBodega;
  final TipoBodega tipoBodega;
  final String sucursalId;
  final String nombreSucursal;
}
