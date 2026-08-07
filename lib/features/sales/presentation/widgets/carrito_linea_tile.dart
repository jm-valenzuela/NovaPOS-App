import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/promocion_grupo.dart';
import '../../domain/models/linea_carrito.dart';
import '../theme/pos_colors.dart';

class CarritoLineaTile extends StatelessWidget {
  const CarritoLineaTile({
    super.key,
    required this.linea,
    required this.onCambiarCantidad,
    required this.onQuitar,
    this.onEditarCantidad,
    this.bloqueado = false,
  });

  final LineaCarrito linea;
  final ValueChanged<double> onCambiarCantidad;
  final VoidCallback onQuitar;

  /// true una vez que la Venta ya existe en el servidor (se pidió un
  /// descuento general) — las líneas ya se agregaron allá, así que
  /// cambiarlas localmente las desincronizaría. Deshabilita cantidad,
  /// quitar y el diálogo de editar cantidad; el descuento en sí sigue
  /// gestionándose desde el panel del carrito, no desde acá.
  final bool bloqueado;

  /// Abre el diálogo para tipear una cantidad exacta — obligatorio para
  /// productos por Kilogramo/Litro (un peso no se ajusta de a 1 en 1), y
  /// disponible también para productos por Unidad tocando la cantidad,
  /// para cuando hace falta un número grande (ej. 2000 sacos de cemento)
  /// sin tocar "+" esa cantidad de veces.
  final VoidCallback? onEditarCantidad;

  @override
  Widget build(BuildContext context) {
    final unidad = linea.producto.unidad;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: PosColors.textMuted,
            tooltip: 'Quitar del carrito',
            onPressed: bloqueado ? null : onQuitar,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.producto.nombreProducto,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (unidad.esPesable)
                  InkWell(
                    key: const Key('carritoCantidadPesable'),
                    onTap: bloqueado ? null : onEditarCantidad,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${linea.cantidad} ${unidad.abreviatura}',
                          style: const TextStyle(color: PosColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.edit, size: 13, color: PosColors.accent),
                        const SizedBox(width: 4),
                        if (linea.producto.ofertaVigente) ...[
                          Text(
                            MonedaFormatter.formatear(linea.producto.precioVenta),
                            style: const TextStyle(
                              color: PosColors.precioTachado,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'x ${MonedaFormatter.formatear(linea.producto.precioEfectivo)}/${unidad.abreviatura}',
                          style: TextStyle(
                            color: linea.producto.ofertaVigente ? PosColors.accent : PosColors.textMuted,
                            fontSize: 12,
                            fontWeight: linea.producto.ofertaVigente ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        color: PosColors.textMuted,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: bloqueado ? null : () => onCambiarCantidad(linea.cantidad - 1),
                      ),
                      InkWell(
                        key: const Key('carritoCantidadUnidad'),
                        onTap: bloqueado ? null : onEditarCantidad,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            linea.cantidad % 1 == 0 ? linea.cantidad.toInt().toString() : linea.cantidad.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PosColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        color: PosColors.textMuted,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: bloqueado ? null : () => onCambiarCantidad(linea.cantidad + 1),
                      ),
                      const SizedBox(width: 4),
                      if (linea.producto.ofertaVigente) ...[
                        Text(
                          MonedaFormatter.formatear(linea.producto.precioVenta),
                          style: const TextStyle(
                            color: PosColors.precioTachado,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          'x ${MonedaFormatter.formatear(linea.producto.precioEfectivo)}',
                          style: TextStyle(
                            color: linea.producto.ofertaVigente ? PosColors.accent : PosColors.textMuted,
                            fontSize: 12,
                            fontWeight: linea.producto.ofertaVigente ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (linea.porcentajeDescuentoVolumenHistorico != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_formatearPorcentaje(linea.porcentajeDescuentoVolumenHistorico!)}% dto. por volumen aplicado',
                      style: const TextStyle(color: PosColors.stockOk, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (linea.montoDescuentoPromocionHistorico != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _etiquetaPromocionHistorica(linea),
                      style: const TextStyle(color: PosColors.stockOk, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (linea.ofertaAplicadaHistorico)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Oferta aplicada',
                      style: TextStyle(color: PosColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (linea.aplicaDescuentoVolumen)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_formatearPorcentaje(linea.producto.porcentajeDescuentoVolumen!)}% dto. por volumen aplicado',
                      style: const TextStyle(color: PosColors.stockOk, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (linea.aplicaPromocionGrupo)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${PromocionGrupo.etiqueta(linea.producto.cantidadPorGrupoPromocion!, linea.producto.porcentajeDescuentoUnidadPromocion!)} aplicado',
                      style: const TextStyle(color: PosColors.stockOk, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (linea.producto.ofertaVigente)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Oferta aplicada',
                      style: TextStyle(color: PosColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              MonedaFormatter.formatear(linea.subtotal),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatearPorcentaje(double porcentaje) =>
    porcentaje.truncateToDouble() == porcentaje ? porcentaje.toInt().toString() : porcentaje.toString();

/// Al rescatar, el preset (2x1, 4x3, etc.) viaja resuelto desde la
/// Variante (ver LineaCotizacionDetalle.CantidadPorGrupoPromocion en el
/// backend) — si sigue disponible, se muestra la misma etiqueta que en
/// una línea en vivo, en vez del texto genérico "Promoción aplicada".
/// El preset puede faltar si la Variante fue desactivada o cambió de
/// promoción desde que se guardó la Cotización — ahí sí queda el texto
/// genérico, con el Monto histórico real (nunca el preset actual).
String _etiquetaPromocionHistorica(LineaCarrito linea) {
  final cantidadPorGrupo = linea.producto.cantidadPorGrupoPromocion;
  final porcentaje = linea.producto.porcentajeDescuentoUnidadPromocion;
  if (cantidadPorGrupo != null && porcentaje != null) {
    return '${PromocionGrupo.etiqueta(cantidadPorGrupo, porcentaje)} aplicado';
  }
  return 'Promoción aplicada (-${MonedaFormatter.formatear(linea.montoDescuentoPromocionHistorico!)})';
}
