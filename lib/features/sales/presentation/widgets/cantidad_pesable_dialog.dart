import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/producto_vendible.dart';

/// Para productos por Kilogramo o Litro — a diferencia de un producto por
/// Unidad (que se agrega directo y se ajusta de a 1 en 1), acá hace falta
/// que el Cajero tipee el peso/volumen exacto (ej. 0.350 kg) antes de
/// agregarlo al carrito, mismo criterio que una balanza de POS real.
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
    return AlertDialog(
      title: Text(widget.producto.nombreProducto),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${MonedaFormatter.formatear(widget.producto.precioVenta)} / ${unidad.abreviatura}'),
          const SizedBox(height: 16),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextField(
            key: const Key('cantidadPesable'),
            controller: _cantidadController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Cantidad (${unidad.abreviatura})'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    Navigator.of(context).pop(cantidad);
  }
}
