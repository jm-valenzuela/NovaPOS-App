import '../../../catalog/domain/models/producto_vendible.dart';

/// El carrito es puro estado de cliente hasta que se presiona "Cobrar" —
/// el backend no tiene forma de editar/eliminar una línea ya agregada a
/// una Venta (solo AgregarLinea, ConfirmarVenta), así que armar el
/// carrito recién contra la API en el momento del cobro es la única
/// forma sana de soportar "agregar, quitar, cambiar cantidad" antes de
/// confirmar.
class LineaCarrito {
  const LineaCarrito({required this.producto, required this.cantidad});

  final ProductoVendible producto;
  final double cantidad;

  /// true si esta línea alcanza el umbral del descuento por volumen del
  /// Producto — mismo criterio que Venta.AgregarLinea en el backend
  /// (LineaVenta.Crear), calculado acá porque el carrito es local hasta
  /// el Cobrar (ver LineaCarrito, comentario de clase).
  bool get aplicaDescuentoVolumen {
    final minima = producto.cantidadMinimaDescuentoVolumen;
    return minima != null && cantidad >= minima;
  }

  double get subtotalSinDescuento => producto.precioVenta * cantidad;

  double get subtotal {
    final porcentaje = producto.porcentajeDescuentoVolumen;
    if (!aplicaDescuentoVolumen || porcentaje == null) return subtotalSinDescuento;
    return subtotalSinDescuento * (1 - porcentaje / 100);
  }

  LineaCarrito copyWith({double? cantidad}) =>
      LineaCarrito(producto: producto, cantidad: cantidad ?? this.cantidad);
}
