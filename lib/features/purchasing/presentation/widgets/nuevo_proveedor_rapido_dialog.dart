import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/proveedor.dart';
import '../providers/purchasing_providers.dart';

/// Alta rápida de Proveedor desde SelectorProveedorDialog — mismo criterio
/// que NuevoClientePosDialog (Sales): subconjunto de campos (sin Plazo de
/// Pago, que se completa después desde Proveedores si hace falta), y arma
/// el ProveedorResumen a devolver con los datos recién ingresados porque
/// crearProveedor solo retorna el id.
class NuevoProveedorRapidoDialog extends ConsumerStatefulWidget {
  const NuevoProveedorRapidoDialog({super.key});

  @override
  ConsumerState<NuevoProveedorRapidoDialog> createState() => _NuevoProveedorRapidoDialogState();
}

class _NuevoProveedorRapidoDialogState extends ConsumerState<NuevoProveedorRapidoDialog> {
  final _rutController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Proveedor'),
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
              key: const Key('nuevoProveedorRapidoRut'),
              controller: _rutController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'RUT'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoProveedorRapidoNombre'),
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre / Razón Social'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoProveedorRapidoEmail'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoProveedorRapidoTelefono'),
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('nuevoProveedorRapidoGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
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

    final rutTexto = _rutController.text.trim();
    if (rutTexto.isEmpty) {
      setState(() => _error = 'El RUT es obligatorio.');
      return;
    }
    if (!RutValidator.esValido(rutTexto)) {
      setState(() => _error = 'El RUT no es válido.');
      return;
    }

    final rut = RutValidator.normalizarConGuion(rutTexto);
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final id = await ref.read(purchasingRepositoryProvider).crearProveedor(
            rut: rut,
            nombre: nombre,
            email: email,
            telefono: telefono,
          );

      if (!mounted) return;
      Navigator.of(context).pop(ProveedorResumen(id: id, rut: rut, nombre: nombre, email: email, telefono: telefono));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }
}
