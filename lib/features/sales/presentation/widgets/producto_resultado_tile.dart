import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/producto_vendible.dart';

class ProductoResultadoTile extends StatelessWidget {
  const ProductoResultadoTile({super.key, required this.producto, required this.onAgregar, this.stock});

  final ProductoVendible producto;
  final VoidCallback onAgregar;

  /// Null = sin dato de stock todavía (Bodega no resuelta, o la Variante
  /// no tiene Existencia registrada) — en ese caso no se muestra badge,
  /// nunca se bloquea la venta por falta de este dato informativo.
  final double? stock;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(producto.nombreProducto),
      subtitle: Text(producto.sku),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stock != null) ...[
            _BadgeStock(cantidad: stock!),
            const SizedBox(width: 8),
          ],
          Text(MonedaFormatter.formatear(producto.precioVenta)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Agregar al carrito',
            onPressed: onAgregar,
          ),
        ],
      ),
      onTap: onAgregar,
    );
  }
}

class _BadgeStock extends StatelessWidget {
  const _BadgeStock({required this.cantidad});

  final double cantidad;

  @override
  Widget build(BuildContext context) {
    final sinStock = cantidad <= 0;
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: sinStock ? colores.errorContainer : colores.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Stock ${cantidad.toStringAsFixed(cantidad.truncateToDouble() == cantidad ? 0 : 1)}',
        style: TextStyle(
          fontSize: 12,
          color: sinStock ? colores.onErrorContainer : colores.onSecondaryContainer,
        ),
      ),
    );
  }
}
