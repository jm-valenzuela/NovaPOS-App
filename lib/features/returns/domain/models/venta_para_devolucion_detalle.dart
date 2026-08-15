/// Espejo de LineaVentaParaDevolucion — CantidadYaDevuelta viene de sumar
/// todas las Notas de Crédito previas de esta Venta (cualquier Estado, el
/// producto ya salió físicamente), así que el máximo devolvible por línea
/// es Cantidad - CantidadYaDevuelta.
class LineaVentaParaDevolucion {
  const LineaVentaParaDevolucion({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.cantidadYaDevuelta,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory LineaVentaParaDevolucion.fromJson(Map<String, dynamic> json) => LineaVentaParaDevolucion(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        cantidadYaDevuelta: (json['cantidadYaDevuelta'] as num).toDouble(),
        precioUnitario: (json['precioUnitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidad;
  final double cantidadYaDevuelta;
  final double precioUnitario;
  final double subtotal;

  double get cantidadDevolvible => cantidad - cantidadYaDevuelta;
}

/// Espejo de VentaParaDevolucionDetalle — detalle de la Venta elegida (paso
/// 2 de RegistrarDevolucionScreen). ClienteEsGenerico avisa que hay que
/// exigir elegir/crear un Cliente real antes de registrar la devolución
/// (ver Cliente.RutClienteGenerico en el backend). PagadaIntegramenteEnEfectivo
/// habilita el toggle "Reembolsar en efectivo ahora": si la Venta se pagó
/// con Tarjeta/Crédito/Nota de Crédito, ese dinero nunca entró como
/// efectivo a la Caja, así que reembolsarlo en efectivo dejaría un
/// faltante real en el arqueo (regla espejo en el backend, fail-closed).
class VentaParaDevolucionDetalle {
  const VentaParaDevolucionDetalle({
    required this.ventaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.clienteEsGenerico,
    required this.total,
    required this.pagadaIntegramenteEnEfectivo,
    required this.lineas,
  });

  factory VentaParaDevolucionDetalle.fromJson(Map<String, dynamic> json) => VentaParaDevolucionDetalle(
        ventaId: json['ventaId'] as String,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        clienteEsGenerico: json['clienteEsGenerico'] as bool,
        total: (json['total'] as num).toDouble(),
        pagadaIntegramenteEnEfectivo: json['pagadaIntegramenteEnEfectivo'] as bool,
        lineas: (json['lineas'] as List<dynamic>)
            .map((l) => LineaVentaParaDevolucion.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  final String ventaId;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final bool clienteEsGenerico;
  final double total;
  final bool pagadaIntegramenteEnEfectivo;
  final List<LineaVentaParaDevolucion> lineas;
}
