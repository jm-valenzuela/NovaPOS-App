import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../providers/pos_providers.dart';

/// Alta rápida de Cliente desde el selector del POS — subconjunto de campos
/// de ClienteFormDialog (customers feature): solo lo que un cajero necesita
/// para identificar a alguien en el momento, sin los datos de Factura (Giro/
/// Dirección/Comuna/Ciudad), que se completan después desde la mantención
/// de Clientes si hace falta. Mismo criterio que ahí: RUT obligatorio al
/// registrar (ver Cliente.Rut en el backend — nulo solo para el Cliente
/// Genérico sembrado en UC-01).
///
/// Llama a customerRepositoryProvider directamente (no a clientesAdminProvider,
/// que recarga el listado completo de la pantalla de mantención — trabajo
/// irrelevante acá) y arma el ClienteResumen a devolver con los datos recién
/// ingresados, porque crearCliente solo retorna el id.
class NuevoClientePosDialog extends ConsumerStatefulWidget {
  const NuevoClientePosDialog({super.key});

  @override
  ConsumerState<NuevoClientePosDialog> createState() => _NuevoClientePosDialogState();
}

class _NuevoClientePosDialogState extends ConsumerState<NuevoClientePosDialog> {
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
      title: const Text('Nuevo Cliente'),
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
              key: const Key('nuevoClientePosRut'),
              controller: _rutController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'RUT'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoClientePosNombre'),
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoClientePosEmail'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email (opcional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('nuevoClientePosTelefono'),
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
          key: const Key('nuevoClientePosGuardar'),
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
      final id = await ref.read(customerRepositoryProvider).crearCliente(
            nombre: nombre,
            rut: rut,
            email: email,
            telefono: telefono,
          );

      if (!mounted) return;
      Navigator.of(context).pop(ClienteResumen(id: id, rut: rut, nombre: nombre, email: email, telefono: telefono));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }
}
