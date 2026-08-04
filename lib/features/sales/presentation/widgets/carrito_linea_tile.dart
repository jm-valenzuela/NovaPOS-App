import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/linea_carrito.dart';
import '../theme/pos_colors.dart';

class CarritoLineaTile extends StatelessWidget {
  const CarritoLineaTile({
    super.key,
    required this.linea,
    required this.onCambiarCantidad,
    required this.onQuitar,
    this.onEditarCantidadPesable,
  });

  final LineaCarrito linea;
  final ValueChanged<double> onCambiarCantidad;
  final VoidCallback onQuitar;

  /// Solo se usa (y solo se muestra el control táctil en vez de los
  /// botones +/-) cuando `linea.producto.unidad.esPesable` — un peso o
  /// volumen exacto no se ajusta de a 1 en 1.
  final VoidCallback? onEditarCantidadPesable;

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
            onPressed: onQuitar,
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
                    onTap: onEditarCantidadPesable,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${linea.cantidad} ${unidad.abreviatura}',
                          style: const TextStyle(color: PosColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.edit, size: 13, color: PosColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'x ${MonedaFormatter.formatear(linea.producto.precioVenta)}/${unidad.abreviatura}',
                          style: const TextStyle(color: PosColors.textMuted, fontSize: 12),
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
                        onPressed: () => onCambiarCantidad(linea.cantidad - 1),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          linea.cantidad % 1 == 0 ? linea.cantidad.toInt().toString() : linea.cantidad.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: PosColors.textMuted, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        color: PosColors.textMuted,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () => onCambiarCantidad(linea.cantidad + 1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'x ${MonedaFormatter.formatear(linea.producto.precioVenta)}',
                        style: const TextStyle(color: PosColors.textMuted, fontSize: 12),
                      ),
                    ],
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
