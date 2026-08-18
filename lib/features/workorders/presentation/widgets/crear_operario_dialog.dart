import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workorders_providers.dart';

/// Alta de un Operario — en el fondo es un Usuario real del sistema
/// (con login propio), reutilizando POST /usuarios (mismo endpoint que
/// crea cualquier Usuario) — "Operario" es solo el nombre que le da esta
/// pantalla al concepto, ver CrearUsuarioCommand en el backend.
class CrearOperarioDialog extends ConsumerStatefulWidget {
  const CrearOperarioDialog({super.key});

  @override
  ConsumerState<CrearOperarioDialog> createState() => _CrearOperarioDialogState();
}

class _CrearOperarioDialogState extends ConsumerState<CrearOperarioDialog> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _rolId;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (nombre.isEmpty || email.isEmpty || password.isEmpty || _rolId == null) {
      setState(() => _error = 'Completa nombre, email, contraseña y Rol.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final ok = await ref.read(operariosProvider.notifier).crear(
          nombreCompleto: nombre,
          email: email,
          password: password,
          rolId: _rolId!,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(operariosProvider).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider);

    return AlertDialog(
      title: const Text('Nuevo Operario'),
      content: SizedBox(
        width: 400,
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
              key: const Key('crearOperarioNombre'),
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('crearOperarioEmail'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('crearOperarioPassword'),
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            roles.when(
              data: (lista) => DropdownButtonFormField<String>(
                key: const Key('crearOperarioRol'),
                value: _rolId,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [for (final rol in lista) DropdownMenuItem(value: rol.id, child: Text(rol.nombre))],
                onChanged: (valor) => setState(() => _rolId = valor),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('No se pudieron cargar los Roles.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('crearOperarioGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}
