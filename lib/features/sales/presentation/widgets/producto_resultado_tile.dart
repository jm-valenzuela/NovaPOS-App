import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/producto_vendible.dart';

class ProductoResultadoTile extends StatelessWidget {
  const ProductoResultadoTile({super.key, required this.producto, required this.onAgregar});

  final ProductoVendible producto;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(producto.nombreProducto),
      subtitle: Text(producto.sku),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
