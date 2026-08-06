import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/proveedor.dart';
import '../providers/purchasing_providers.dart';

/// Un solo diálogo para crear y editar — `existente == null` es alta (pide
/// Rut, validado con el mismo algoritmo que el backend), `existente != null`
/// es edición (Rut fijo, no editable — ver Proveedor.Actualizar en el backend).
class ProveedorFormDialog extends ConsumerStatefulWidget {
  const ProveedorFormDialog({super.key, this.existente});

  final ProveedorResumen? existente;

  @override
  ConsumerState<ProveedorFormDialog> createState() => _ProveedorFormDialogState();
}

class _ProveedorFormDialogState extends ConsumerState<ProveedorFormDialog> {
  late final _rutController = TextEditingController(text: widget.existente?.rut ?? '');
  late final _nombreController = TextEditingController(text: widget.existente?.nombre ?? '');
  late final _emailController = TextEditingController(text: widget.existente?.email ?? '');
  late final _telefonoController = TextEditingController(text: widget.existente?.telefono ?? '');
  late final _plazoPagoController = TextEditingController(text: (widget.existente?.plazoPagoDias ?? 0).toString());
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.existente != null;

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _plazoPagoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            TextField(
              key: const Key('proveedorRut'),
              controller: _rutController,
              enabled: !_esEdicion,
              decoration: const InputDecoration(labelText: 'RUT'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('proveedorNombre'),
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('proveedorEmail'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('proveedorTelefono'),
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('proveedorPlazoPago'),
              controller: _plazoPagoController,
              decoration: const InputDecoration(labelText: 'Plazo de pago (días)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('proveedorGuardar'),
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

    final plazoPagoDias = int.tryParse(_plazoPagoController.text.trim()) ?? 0;
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = _esEdicion
        ? await ref.read(proveedoresProvider.notifier).actualizar(
              proveedorId: widget.existente!.id,
              nombre: nombre,
              email: email,
              telefono: telefono,
              plazoPagoDias: plazoPagoDias,
            )
        : await _crear(nombre, email, telefono, plazoPagoDias);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(proveedoresProvider).error ?? 'No se pudo guardar el Proveedor.';
      });
    }
  }

  Future<bool> _crear(String nombre, String? email, String? telefono, int plazoPagoDias) async {
    final rut = _rutController.text.trim();
    if (!RutValidator.esValido(rut)) {
      setState(() {
        _guardando = false;
        _error = 'El RUT no es válido.';
      });
      return false;
    }

    return ref.read(proveedoresProvider.notifier).crear(
          rut: RutValidator.normalizarConGuion(rut),
          nombre: nombre,
          email: email,
          telefono: telefono,
          plazoPagoDias: plazoPagoDias,
        );
  }
}
