import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workorders_providers.dart';

/// Asigna (o quita) el Operador de un Ítem — reasignable en cualquier
/// momento mientras el Ítem no esté Rechazado ni Terminado. Sin ningún
/// aviso automático al Operador (no existe mecanismo de notificaciones en
/// el sistema todavía) — es solo informativo, visible en el detalle.
class AsignarOperadorDialog extends ConsumerStatefulWidget {
  const AsignarOperadorDialog({super.key, required this.ordenTrabajoId, required this.itemId, this.usuarioIdActual});

  final String ordenTrabajoId;
  final String itemId;
  final String? usuarioIdActual;

  @override
  ConsumerState<AsignarOperadorDialog> createState() => _AsignarOperadorDialogState();
}

class _AsignarOperadorDialogState extends ConsumerState<AsignarOperadorDialog> {
  bool _guardando = false;
  String? _error;

  Future<void> _asignar(String? usuarioId) async {
    setState(() {
      _guardando = true;
      _error = null;
    });

    final ok = await ref
        .read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId).notifier)
        .asignarOperadorItem(itemId: widget.itemId, usuarioId: usuarioId);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId)).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuariosProvider);

    return AlertDialog(
      title: const Text('Asignar Operador'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_guardando)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              usuariosAsync.when(
                data: (usuarios) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.usuarioIdActual != null)
                      ListTile(
                        key: const Key('asignarOperadorQuitar'),
                        leading: const Icon(Icons.person_off_outlined),
                        title: const Text('Sin asignar'),
                        onTap: () => _asignar(null),
                      ),
                    for (final usuario in usuarios)
                      ListTile(
                        key: Key('asignarOperador_${usuario.id}'),
                        leading: Icon(
                          usuario.id == widget.usuarioIdActual ? Icons.radio_button_checked : Icons.person_outline,
                        ),
                        title: Text(usuario.nombreCompleto),
                        onTap: () => _asignar(usuario.id),
                      ),
                  ],
                ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (e, _) => Text(e.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
