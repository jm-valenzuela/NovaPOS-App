import 'unidad_medida.dart';

/// Espejo de ProductoVendibleResumen (BuscarProductosVendiblesQuery en el backend).
class ProductoVendible {
  const ProductoVendible({
    required this.varianteProductoId,
    required this.productoId,
    required this.nombreProducto,
    required this.sku,
    required this.codigoBarras,
    required this.precioVenta,
    required this.unidadMedida,
    this.cantidadMinimaDescuentoVolumen,
    this.porcentajeDescuentoVolumen,
    this.cantidadPorGrupoPromocion,
    this.porcentajeDescuentoUnidadPromocion,
    this.precioOferta,
    this.ofertaDesde,
    this.ofertaHasta,
  });

  factory ProductoVendible.fromJson(Map<String, dynamic> json) => ProductoVendible(
        varianteProductoId: json['varianteProductoId'] as String,
        productoId: json['productoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        codigoBarras: json['codigoBarras'] as String?,
        precioVenta: (json['precioVenta'] as num).toDouble(),
        unidadMedida: json['unidadMedida'] as int,
        cantidadMinimaDescuentoVolumen: json['cantidadMinimaDescuentoVolumen'] as int?,
        porcentajeDescuentoVolumen: (json['porcentajeDescuentoVolumen'] as num?)?.toDouble(),
        cantidadPorGrupoPromocion: json['cantidadPorGrupoPromocion'] as int?,
        porcentajeDescuentoUnidadPromocion: (json['porcentajeDescuentoUnidadPromocion'] as num?)?.toDouble(),
        precioOferta: (json['precioOferta'] as num?)?.toDouble(),
        ofertaDesde: json['ofertaDesde'] == null ? null : DateTime.parse(json['ofertaDesde'] as String),
        ofertaHasta: json['ofertaHasta'] == null ? null : DateTime.parse(json['ofertaHasta'] as String),
      );

  final String varianteProductoId;
  final String productoId;
  final String nombreProducto;
  final String sku;
  final String? codigoBarras;
  final double precioVenta;
  final int unidadMedida;

  /// "Desde N unidades, X% dto." — ambos null si la Variante no tiene esta
  /// promoción configurada (ver VarianteProducto.CantidadMinimaDescuentoVolumen
  /// en el backend).
  final int? cantidadMinimaDescuentoVolumen;
  final double? porcentajeDescuentoVolumen;

  /// Promoción por grupo (2x1, 6x5, "segundo al 40%", etc.) — ambos null si
  /// no aplica. Mutuamente excluyente con el descuento por volumen de
  /// arriba (ver VarianteProducto.CantidadPorGrupoPromocion en el backend).
  final int? cantidadPorGrupoPromocion;
  final double? porcentajeDescuentoUnidadPromocion;

  /// Precio de oferta vigente solo dentro de [ofertaDesde, ofertaHasta]
  /// (ambos inclusive) — mutuamente excluyente con las promociones de
  /// arriba (ver VarianteProducto.ValidarPromocionesNoSeSuperponen en el
  /// backend). Todos null si la Variante no tiene oferta configurada.
  final double? precioOferta;
  final DateTime? ofertaDesde;
  final DateTime? ofertaHasta;

  UnidadMedida get unidad => UnidadMedida.desdeValor(unidadMedida);

  /// Evaluación en el reloj del dispositivo, solo para mostrar el precio en
  /// pantalla — el cargo real siempre se resuelve en el servidor
  /// (VarianteProducto.PrecioVigente), que no confía en la hora del
  /// cliente para una decisión con impacto financiero.
  bool get ofertaVigente {
    if (precioOferta == null || ofertaDesde == null || ofertaHasta == null) return false;
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    return !hoySoloFecha.isBefore(ofertaDesde!) && !hoySoloFecha.isAfter(ofertaHasta!);
  }

  /// Precio a usar para mostrar/calcular en el carrito — precioOferta si
  /// está vigente hoy, precioVenta en cualquier otro caso.
  double get precioEfectivo => ofertaVigente ? precioOferta! : precioVenta;
}
