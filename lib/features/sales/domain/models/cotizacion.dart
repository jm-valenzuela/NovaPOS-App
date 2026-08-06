/// Espejo de CotizacionResumen — fila liviana para "rescatar cotización" en el POS.
class CotizacionResumen {
  const CotizacionResumen({
    required this.ventaId,
    required this.fechaVenta,
    required this.clienteId,
    required this.clienteNombre,
    required this.cantidadLineas,
    required this.total,
  });

  factory CotizacionResumen.fromJson(Map<String, dynamic> json) => CotizacionResumen(
        ventaId: json['ventaId'] as String,
        fechaVenta: DateTime.parse(json['fechaVenta'] as String),
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        cantidadLineas: json['cantidadLineas'] as int,
        total: (json['total'] as num).toDouble(),
      );

  final String ventaId;
  final DateTime fechaVenta;
  final String clienteId;
  final String clienteNombre;
  final int cantidadLineas;
  final double total;
}

/// Espejo de LineaCotizacionDetalle — de solo lectura, con el nombre del
/// Producto ya resuelto (mismo criterio que LineaDescuentoPendienteDetalle).
class LineaCotizacionDetalle {
  const LineaCotizacionDetalle({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory LineaCotizacionDetalle.fromJson(Map<String, dynamic> json) => LineaCotizacionDetalle(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        precioUnitario: (json['precioUnitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
}

/// Espejo de CotizacionDetalle — detalle completo para rehidratar el
/// carrito del POS al "rescatar" una Cotización guardada.
class CotizacionDetalle {
  const CotizacionDetalle({
    required this.ventaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.total,
    required this.lineas,
  });

  factory CotizacionDetalle.fromJson(Map<String, dynamic> json) => CotizacionDetalle(
        ventaId: json['ventaId'] as String,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        total: (json['total'] as num).toDouble(),
        lineas: (json['lineas'] as List<dynamic>)
            .map((l) => LineaCotizacionDetalle.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  final String ventaId;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final double total;
  final List<LineaCotizacionDetalle> lineas;
}
