/// Espejo de la respuesta de confirmar una Venta (Venta.DesglosarIva en el
/// backend) — los precios de NovaPOS son IVA incluido, así que Neto/Iva se
/// derivan de Total, nunca al revés.
class ResumenVenta {
  const ResumenVenta({required this.neto, required this.iva, required this.total});

  factory ResumenVenta.fromJson(Map<String, dynamic> json) => ResumenVenta(
        neto: (json['neto'] as num).toDouble(),
        iva: (json['iva'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );

  /// Mismo cálculo que Venta.DesglosarIva en el backend — usado para el
  /// desglose en vivo del carrito, antes de que exista una Venta real en
  /// el servidor (ver LineaCarrito: el carrito es puro estado de cliente).
  factory ResumenVenta.calcular(double total) {
    const tasaIva = 0.19;
    final neto = (total / (1 + tasaIva)).roundToDouble();
    return ResumenVenta(neto: neto, iva: total - neto, total: total);
  }

  final double neto;
  final double iva;
  final double total;
}
