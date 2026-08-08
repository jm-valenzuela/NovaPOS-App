import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchasing_providers.dart';

/// Alta de un Plazo de Pago del catálogo de Proveedores — nombre + lista de
/// cuotas en días (ej. "30-60-90 días" → [30, 60, 90]). El backend exige
/// al menos una cuota y días estrictamente crecientes (PlazoPago.Crear).
class CrearPlazoPagoDialog extends ConsumerStatefulWidget {
  const CrearPlazoPagoDialog({super.key});

  @override
  ConsumerState<CrearPlazoPagoDialog> createState() => _CrearPlazoPagoDialogState();
}

class _CrearPlazoPagoDialogState extends ConsumerState<CrearPlazoPagoDialog> {
  final _nombreController = TextEditingController();
  final List<TextEditingController> _cuotaControllers = [TextEditingController()];
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    for (final c in _cuotaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _agregarCuota() => setState(() => _cuotaControllers.add(TextEditingController()));

  void _quitarCuota(int index) => setState(() {
        _cuotaControllers[index].dispose();
        _cuotaControllers.removeAt(index);
      });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Plazo de Pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            TextField(
              key: const Key('plazoPagoNombre'),
              controller: _nombreController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej: 30-60-90 días'),
            ),
            const SizedBox(height: 16),
            Text('Cuotas (días desde el documento)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < _cuotaControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: Key('plazoPagoCuota_$i'),
                        controller: _cuotaControllers[i],
                        decoration: InputDecoration(labelText: 'Cuota ${i + 1}'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    if (_cuotaControllers.length > 1)
                      IconButton(
                        key: Key('plazoPagoQuitarCuota_$i'),
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _quitarCuota(i),
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              key: const Key('plazoPagoAgregarCuota'),
              onPressed: _agregarCuota,
              icon: const Icon(Icons.add),
              label: const Text('Agregar cuota'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('plazoPagoGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }

    final dias = <int>[];
    for (final c in _cuotaControllers) {
      final valor = int.tryParse(c.text.trim());
      if (valor == null) {
        setState(() => _error = 'Cada cuota debe tener un número de días válido.');
        return;
      }
      dias.add(valor);
    }
    for (var i = 1; i < dias.length; i++) {
      if (dias[i] <= dias[i - 1]) {
        setState(() => _error = 'Los días de cada cuota deben ser estrictamente crecientes.');
        return;
      }
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(plazosPagoProveedorProvider.notifier).crear(nombre: nombre, diasCuotas: dias);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(plazosPagoProveedorProvider).error ?? 'No se pudo guardar el Plazo de Pago.';
      });
    }
  }
}
