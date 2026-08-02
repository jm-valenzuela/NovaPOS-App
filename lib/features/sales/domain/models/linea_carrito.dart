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

  double get subtotal => producto.precioVenta * cantidad;

  LineaCarrito copyWith({double? cantidad}) =>
      LineaCarrito(producto: producto, cantidad: cantidad ?? this.cantidad);
}
