import '../../../catalog/domain/models/producto_vendible.dart';

/// El carrito es puro estado de cliente hasta que se presiona "Cobrar" —
/// el backend no tiene forma de editar/eliminar una línea ya agregada a
/// una Venta (solo AgregarLinea, ConfirmarVenta), así que armar el
/// carrito recién contra la API en el momento del cobro es la única
/// forma sana de soportar "agregar, quitar, cambiar cantidad" antes de
/// confirmar.
class LineaCarrito {
  const LineaCarrito({
    required this.producto,
    required this.cantidad,
    this.porcentajeDescuentoVolumenHistorico,
    this.montoDescuentoPromocionHistorico,
  });

  final ProductoVendible producto;
  final double cantidad;

  /// Descuento por volumen ya aplicado a esta línea al rescatar una
  /// Cotización guardada — hecho histórico del backend (LineaVenta.
  /// PorcentajeDescuentoAplicado), no la regla vigente del catálogo (que
  /// pudo cambiar desde que se guardó). Null en una línea armada en vivo.
  final double? porcentajeDescuentoVolumenHistorico;

  /// Igual que arriba, pero para una promoción por grupo (2x1, 6x5, etc.)
  /// — se guarda solo el monto (LineaVenta.MontoDescuentoPromocion), no
  /// los parámetros (N/%) del preset, que no son reconstruibles a partir
  /// del monto solo, así que no se puede mostrar el mismo texto "2x1" que
  /// en una línea en vivo, solo que hubo una promoción y cuánto descontó.
  final double? montoDescuentoPromocionHistorico;

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

  /// Usa precioEfectivo (Oferta si está vigente hoy, PrecioVenta si no) —
  /// Oferta es mutuamente excluyente con el descuento por volumen y la
  /// promoción por grupo (ver ValidarPromocionesNoSeSuperponen en el
  /// backend), así que nunca se combinan.
  double get subtotalSinDescuento => producto.precioEfectivo * cantidad;

  /// Si vienen campos históricos (línea rescatada de una Cotización), el
  /// descuento real ya ocurrido manda sobre cualquier regla vigente del
  /// catálogo — es lo que efectivamente se cobró, no una estimación nueva.
  /// Sin esto, mostrar producto.precioVenta como el precio unitario real
  /// (en vez del promedio subtotal/cantidad que se usaba antes) habría
  /// duplicado el descuento fuera del Subtotal, inflando el Total.
  double get subtotal {
    if (porcentajeDescuentoVolumenHistorico != null) {
      return subtotalSinDescuento * (1 - porcentajeDescuentoVolumenHistorico! / 100);
    }
    if (montoDescuentoPromocionHistorico != null) {
      return subtotalSinDescuento - montoDescuentoPromocionHistorico!;
    }

    final porcentajeVolumen = producto.porcentajeDescuentoVolumen;
    final subtotalConDescuentoVolumen = (aplicaDescuentoVolumen && porcentajeVolumen != null)
        ? subtotalSinDescuento * (1 - porcentajeVolumen / 100)
        : subtotalSinDescuento;
    return subtotalConDescuentoVolumen - montoDescuentoPromocion;
  }

  LineaCarrito copyWith({double? cantidad}) => LineaCarrito(
        producto: producto,
        cantidad: cantidad ?? this.cantidad,
        porcentajeDescuentoVolumenHistorico: porcentajeDescuentoVolumenHistorico,
        montoDescuentoPromocionHistorico: montoDescuentoPromocionHistorico,
      );
}
