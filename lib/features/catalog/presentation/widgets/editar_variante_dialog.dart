import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/producto_admin.dart';
import '../providers/catalog_admin_providers.dart';

const _unidadesMedida = [
  (valor: 0, nombre: 'Unidad'),
  (valor: 1, nombre: 'Kilogramo'),
  (valor: 2, nombre: 'Litro'),
];

/// A diferencia de EditarProductoDialog, no depende de CatalogFormController
/// — no hay cascada de clasificación que resolver, es un PUT directo.
class EditarVarianteDialog extends ConsumerStatefulWidget {
  const EditarVarianteDialog({super.key, required this.variante});

  final VarianteAdmin variante;

  @override
  ConsumerState<EditarVarianteDialog> createState() => _EditarVarianteDialogState();
}

class _EditarVarianteDialogState extends ConsumerState<EditarVarianteDialog> {
  late final _precioController = TextEditingController(text: widget.variante.precioVenta.toString());
  late final _codigoBarrasController = TextEditingController(text: widget.variante.codigoBarras ?? '');
  late final _colorController = TextEditingController(text: widget.variante.color ?? '');
  late final _tallaController = TextEditingController(text: widget.variante.talla ?? '');
  late final _ubicacionController = TextEditingController(text: widget.variante.ubicacionFisica ?? '');
  late int _unidadMedida = widget.variante.unidadMedida;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _precioController.dispose();
    _codigoBarrasController.dispose();
    _colorController.dispose();
    _tallaController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Variante (${widget.variante.sku})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextField(
              key: const Key('editarPrecioVariante'),
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio de venta'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('editarUnidadMedidaVariante'),
              decoration: const InputDecoration(labelText: 'Unidad de medida'),
              value: _unidadMedida,
              items: _unidadesMedida.map((u) => DropdownMenuItem(value: u.valor, child: Text(u.nombre))).toList(),
              onChanged: (valor) => setState(() => _unidadMedida = valor ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarCodigoBarrasVariante'),
              controller: _codigoBarrasController,
              decoration: const InputDecoration(labelText: 'Código de barras (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarColorVariante'),
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarTallaVariante'),
              controller: _tallaController,
              decoration: const InputDecoration(labelText: 'Talla (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarUbicacionVariante'),
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: 'Ubicación física (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('guardarEdicionVariante'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio < 0) {
      setState(() => _error = 'Ingresa un precio válido');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await ref.read(catalogAdminRepositoryProvider).actualizarVariante(
            varianteProductoId: widget.variante.varianteProductoId,
            precioVenta: precio,
            unidadMedida: _unidadMedida,
            codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
            color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
            talla: _tallaController.text.trim().isEmpty ? null : _tallaController.text.trim(),
            ubicacionFisica: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
          );

      if (!mounted) return;
      ref.read(productosAdminProvider.notifier).cargar();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }
}
