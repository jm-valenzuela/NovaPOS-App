import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/producto_vendible.dart';
import '../theme/pos_colors.dart';

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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAgregar,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: PosColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stock != null)
                Align(alignment: Alignment.centerRight, child: _BadgeStock(cantidad: stock!)),
              Text(
                producto.nombreProducto,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(producto.sku, style: const TextStyle(fontSize: 12, color: PosColors.textMuted)),
              const SizedBox(height: 8),
              Text(
                MonedaFormatter.formatear(producto.precioVenta),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeStock extends StatelessWidget {
  const _BadgeStock({required this.cantidad});

  final double cantidad;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (cantidad) {
      <= 0 => (PosColors.stockOutBg, PosColors.stockOut),
      <= 5 => (PosColors.stockLowBg, PosColors.stockLow),
      _ => (PosColors.stockOkBg, PosColors.stockOk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        'Stock ${cantidad.toStringAsFixed(cantidad.truncateToDouble() == cantidad ? 0 : 1)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
