import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/cliente_resumen.dart';
import '../providers/customer_admin_providers.dart';

/// Un solo diálogo para crear y editar — a diferencia de Proveedor, el Rut
/// del Cliente es opcional (ver Cliente.cs: ventas de mostrador sin
/// comprador identificado), y tampoco es editable una vez creado.
class ClienteFormDialog extends ConsumerStatefulWidget {
  const ClienteFormDialog({super.key, this.existente});

  final ClienteResumen? existente;

  @override
  ConsumerState<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends ConsumerState<ClienteFormDialog> {
  late final _rutController = TextEditingController(text: widget.existente?.rut ?? '');
  late final _nombreController = TextEditingController(text: widget.existente?.nombre ?? '');
  late final _emailController = TextEditingController(text: widget.existente?.email ?? '');
  late final _telefonoController = TextEditingController(text: widget.existente?.telefono ?? '');
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.existente != null;

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
      title: Text(_esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
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
              key: const Key('clienteRut'),
              controller: _rutController,
              enabled: !_esEdicion,
              decoration: const InputDecoration(labelText: 'RUT (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('clienteNombre'),
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('clienteEmail'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('clienteTelefono'),
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('clienteGuardar'),
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

    final rutTexto = _rutController.text.trim();
    if (!_esEdicion && rutTexto.isNotEmpty && !RutValidator.esValido(rutTexto)) {
      setState(() => _error = 'El RUT no es válido.');
      return;
    }

    // Cupo de crédito y plazo de pago no se editan desde este formulario — requieren
    // una evaluación y autorización aparte (pendiente de diseñar), no un campo libre
    // en el alta/edición general del Cliente. Se reenvían sin cambios en una edición,
    // y en 0 en un alta nueva (mismo default que tenía el Cliente Genérico).
    final cupoCredito = widget.existente?.cupoCredito ?? 0;
    final plazoPagoDias = widget.existente?.plazoPagoDias ?? 0;
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = _esEdicion
        ? await ref.read(clientesAdminProvider.notifier).actualizar(
              clienteId: widget.existente!.id,
              nombre: nombre,
              email: email,
              telefono: telefono,
              cupoCredito: cupoCredito,
              plazoPagoDias: plazoPagoDias,
            )
        : await ref.read(clientesAdminProvider.notifier).crear(
              nombre: nombre,
              rut: rutTexto.isEmpty ? null : RutValidator.normalizarConGuion(rutTexto),
              email: email,
              telefono: telefono,
              cupoCredito: cupoCredito,
              plazoPagoDias: plazoPagoDias,
            );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(clientesAdminProvider).error ?? 'No se pudo guardar el Cliente.';
      });
    }
  }
}
