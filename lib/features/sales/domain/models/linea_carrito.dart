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

  /// Cuántos grupos completos de la promoción (2x1, 6x5, etc.) entran en
  /// la cantidad de esta línea — 0 si no hay promoción configurada o
  /// todavía no se completa ni un grupo. Mismo cálculo que
  /// LineaVenta.Crear en el backend.
  int get gruposCompletosPromocion {
    final cantidadPorGrupo = producto.cantidadPorGrupoPromocion;
    if (cantidadPorGrupo == null) return 0;
    return (cantidad / cantidadPorGrupo).floor();
  }

  bool get aplicaPromocionGrupo => gruposCompletosPromocion >= 1;

  double get montoDescuentoPromocion {
    final porcentaje = producto.porcentajeDescuentoUnidadPromocion;
    if (!aplicaPromocionGrupo || porcentaje == null) return 0;
    return gruposCompletosPromocion * producto.precioVenta * (porcentaje / 100);
  }

  double get subtotalSinDescuento => producto.precioVenta * cantidad;

  double get subtotal {
    final porcentajeVolumen = producto.porcentajeDescuentoVolumen;
    final subtotalConDescuentoVolumen = (aplicaDescuentoVolumen && porcentajeVolumen != null)
        ? subtotalSinDescuento * (1 - porcentajeVolumen / 100)
        : subtotalSinDescuento;
    return subtotalConDescuentoVolumen - montoDescuentoPromocion;
  }

  LineaCarrito copyWith({double? cantidad}) =>
      LineaCarrito(producto: producto, cantidad: cantidad ?? this.cantidad);
}
