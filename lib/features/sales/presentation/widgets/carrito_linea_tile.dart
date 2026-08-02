import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/linea_carrito.dart';

class CarritoLineaTile extends StatelessWidget {
  const CarritoLineaTile({
    super.key,
    required this.linea,
    required this.onCambiarCantidad,
    required this.onQuitar,
  });

  final LineaCarrito linea;
  final ValueChanged<double> onCambiarCantidad;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(linea.producto.nombreProducto),
      subtitle: Text('${MonedaFormatter.formatear(linea.producto.precioVenta)} c/u'),
      leading: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        tooltip: 'Quitar del carrito',
        onPressed: onQuitar,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onCambiarCantidad(linea.cantidad - 1),
          ),
          SizedBox(
            width: 32,
            child: Text(
              linea.cantidad % 1 == 0 ? linea.cantidad.toInt().toString() : linea.cantidad.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onCambiarCantidad(linea.cantidad + 1),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              MonedaFormatter.formatear(linea.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
