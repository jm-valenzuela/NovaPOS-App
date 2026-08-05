/// Espejo de LineaDescuentoPendienteDetalle — a diferencia de LineaCarrito,
/// esto es de solo lectura (viene ya resuelto del backend, con el nombre
/// del Producto incluido).
class LineaDescuentoPendienteDetalle {
  const LineaDescuentoPendienteDetalle({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory LineaDescuentoPendienteDetalle.fromJson(Map<String, dynamic> json) => LineaDescuentoPendienteDetalle(
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

/// Espejo de DetalleDescuentoPendienteResumen — el "Ver más" de
/// DescuentosPendientesScreen: quién es el Cliente y qué Productos/
/// cantidades tiene la Venta, para decidir con el detalle a la vista.
class DetalleDescuentoPendiente {
  const DetalleDescuentoPendiente({
    required this.ventaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.subtotalLineas,
    required this.porcentaje,
    required this.monto,
    required this.lineas,
  });

  factory DetalleDescuentoPendiente.fromJson(Map<String, dynamic> json) => DetalleDescuentoPendiente(
        ventaId: json['ventaId'] as String,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        subtotalLineas: (json['subtotalLineas'] as num).toDouble(),
        porcentaje: (json['porcentaje'] as num?)?.toDouble(),
        monto: (json['monto'] as num?)?.toDouble(),
        lineas: (json['lineas'] as List<dynamic>)
            .map((l) => LineaDescuentoPendienteDetalle.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  final String ventaId;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final double subtotalLineas;
  final double? porcentaje;
  final double? monto;
  final List<LineaDescuentoPendienteDetalle> lineas;
}
