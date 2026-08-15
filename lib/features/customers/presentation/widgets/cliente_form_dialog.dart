import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/cliente_resumen.dart';
import '../providers/customer_admin_providers.dart';

/// Un solo diálogo para crear y editar. El Rut es obligatorio al registrar un
/// Cliente aquí (a diferencia del dominio, que lo permite nulo solo para el
/// Cliente Genérico sembrado automáticamente en UC-01 — ver Cliente.cs), y no
/// es editable una vez asignado — salvo que el Cliente haya quedado sin uno
/// (ej. creado antes de que el alta lo exigiera), caso en el que el campo se
/// habilita para completarlo (Cliente.AsignarRut, no reemplaza uno existente).
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
  late final _giroController = TextEditingController(text: widget.existente?.giro ?? '');
  late final _direccionController = TextEditingController(text: widget.existente?.direccion ?? '');
  late final _comunaController = TextEditingController(text: widget.existente?.comuna ?? '');
  late final _ciudadController = TextEditingController(text: widget.existente?.ciudad ?? '');
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.existente != null;
  bool get _rutFaltante => _esEdicion && (widget.existente!.rut == null || widget.existente!.rut!.trim().isEmpty);
  bool get _rutEditable => !_esEdicion || _rutFaltante;

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _giroController.dispose();
    _direccionController.dispose();
    _comunaController.dispose();
    _ciudadController.dispose();
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
              enabled: _rutEditable,
              decoration: InputDecoration(labelText: _rutFaltante ? 'RUT (completar)' : 'RUT'),
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
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Text('Datos para Factura (opcional)', style: Theme.of(context).textTheme.labelLarge),
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                'Solo necesarios si este Cliente va a recibir una Factura en vez de Boleta.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            TextField(
              key: const Key('clienteGiro'),
              controller: _giroController,
              decoration: const InputDecoration(labelText: 'Giro'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('clienteDireccion'),
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('clienteComuna'),
                    controller: _comunaController,
                    decoration: const InputDecoration(labelText: 'Comuna'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('clienteCiudad'),
                    controller: _ciudadController,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                  ),
                ),
              ],
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
    if (!_esEdicion) {
      if (rutTexto.isEmpty) {
        setState(() => _error = 'El RUT es obligatorio.');
        return;
      }
      if (!RutValidator.esValido(rutTexto)) {
        setState(() => _error = 'El RUT no es válido.');
        return;
      }
    } else if (_rutFaltante && rutTexto.isNotEmpty && !RutValidator.esValido(rutTexto)) {
      setState(() => _error = 'El RUT no es válido.');
      return;
    }

    // Cupo de crédito y Plazo de Pago no se editan desde este formulario —
    // ambos requieren pasar por Solicitar Cupo de Crédito + autorización
    // (ver SolicitarCreditoDialog, Cliente.AutorizarCredito). Se reenvían
    // sin cambios en una edición, y en sus defaults (0 / sin Plazo) en un
    // alta nueva.
    final cupoCredito = widget.existente?.cupoCredito ?? 0;
    final plazoPagoId = widget.existente?.plazoPagoId;
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
    final giro = _giroController.text.trim().isEmpty ? null : _giroController.text.trim();
    final direccion = _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim();
    final comuna = _comunaController.text.trim().isEmpty ? null : _comunaController.text.trim();
    final ciudad = _ciudadController.text.trim().isEmpty ? null : _ciudadController.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });

    bool exito;
    if (_esEdicion) {
      exito = await ref.read(clientesAdminProvider.notifier).actualizar(
            clienteId: widget.existente!.id,
            nombre: nombre,
            email: email,
            telefono: telefono,
            cupoCredito: cupoCredito,
            plazoPagoId: plazoPagoId,
            giro: giro,
            direccion: direccion,
            comuna: comuna,
            ciudad: ciudad,
          );
      if (exito && _rutFaltante && rutTexto.isNotEmpty) {
        exito = await ref.read(clientesAdminProvider.notifier).asignarRut(
              clienteId: widget.existente!.id,
              rut: RutValidator.normalizarConGuion(rutTexto),
            );
      }
    } else {
      exito = await ref.read(clientesAdminProvider.notifier).crear(
            nombre: nombre,
            rut: RutValidator.normalizarConGuion(rutTexto),
            email: email,
            telefono: telefono,
            cupoCredito: cupoCredito,
            plazoPagoId: plazoPagoId,
            giro: giro,
            direccion: direccion,
            comuna: comuna,
            ciudad: ciudad,
          );
    }

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
