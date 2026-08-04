import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/producto_vendible.dart';

/// Para tipear una cantidad exacta en vez de ajustarla de a 1 en 1 — dos
/// casos: productos por Kilogramo/Litro (obligatorio, ver
/// PosScreen._agregarProducto, mismo criterio que una balanza real) y
/// productos por Unidad cuando la cantidad es grande (ej. una Empresa que
/// pide 2000 sacos de cemento — tocar "+" 2000 veces no es razonable). El
/// diálogo se adapta según `producto.unidad.esPesable`: solo pide un
/// número entero cuando no es pesable.
class CantidadPesableDialog extends StatefulWidget {
  const CantidadPesableDialog({super.key, required this.producto, this.cantidadInicial});

  final ProductoVendible producto;

  /// Al editar una línea ya en el carrito, precarga el valor actual en
  /// vez de partir vacío.
  final double? cantidadInicial;

  @override
  State<CantidadPesableDialog> createState() => _CantidadPesableDialogState();
}

class _CantidadPesableDialogState extends State<CantidadPesableDialog> {
  late final _cantidadController =
      TextEditingController(text: widget.cantidadInicial?.toString() ?? '');
  String? _error;

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unidad = widget.producto.unidad;
    final esPesable = unidad.esPesable;
    return AlertDialog(
      title: Text(widget.producto.nombreProducto),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(esPesable
              ? '${MonedaFormatter.formatear(widget.producto.precioVenta)} / ${unidad.abreviatura}'
              : MonedaFormatter.formatear(widget.producto.precioVenta)),
          const SizedBox(height: 16),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextField(
            key: const Key('cantidadPesable'),
            controller: _cantidadController,
            autofocus: true,
            decoration: InputDecoration(labelText: esPesable ? 'Cantidad (${unidad.abreviatura})' : 'Cantidad'),
            keyboardType: TextInputType.numberWithOptions(decimal: esPesable),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cantidadPesableCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('cantidadPesableConfirmar'),
          onPressed: _confirmar,
          child: Text(widget.cantidadInicial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }

  void _confirmar() {
    final cantidad = double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'Ingresa una cantidad válida');
      return;
    }
    if (!widget.producto.unidad.esPesable && cantidad != cantidad.roundToDouble()) {
      setState(() => _error = 'Ingresa un número entero de unidades');
      return;
    }
    Navigator.of(context).pop(cantidad);
  }
}
