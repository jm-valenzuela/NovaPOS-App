import 'linea_carrito.dart';

/// Una línea a mostrar en la representación impresa de una Boleta/Factura
/// — desacoplada de [LineaCarrito] (que exige un [ProductoVendible] real
/// del Catálogo) para que también se pueda imprimir una Venta armada
/// fuera del POS (ej. desde una Orden de Trabajo, con líneas libres de
/// mano de obra sin Producto asociado — ver ObtenerVentaQuery en el
/// backend). Cantidad null en una línea sin Producto (ej. "Balanceo").
class LineaImpresion {
  const LineaImpresion({required this.descripcion, required this.subtotal, this.cantidad, this.precioUnitario});

  /// precioUnitario es el precio real de catálogo (Oferta vigente o PrecioVenta) — nunca subtotal/cantidad, que
  /// da un promedio ficticio en cuanto hay descuento por volumen/promoción por grupo (ver el comentario de
  /// LineaCarrito.subtotal, que documenta este mismo error ya corregido ahí, pero no en la impresión).
  factory LineaImpresion.desdeCarrito(LineaCarrito linea) => LineaImpresion(
        descripcion: linea.producto.nombreProducto,
        cantidad: linea.cantidad,
        subtotal: linea.subtotal,
        precioUnitario: linea.producto.precioEfectivo,
      );

  final String descripcion;
  final double? cantidad;
  final double? precioUnitario;
  final double subtotal;
}
