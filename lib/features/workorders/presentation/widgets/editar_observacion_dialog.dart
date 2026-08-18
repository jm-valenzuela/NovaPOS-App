import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workorders_providers.dart';

/// Nota libre mientras se investiga un Ítem — ej. "buscando en el mercado
/// un parabrisas compatible, contactar a Proveedor X". Lo que ahí se
/// registre es lo que después, cuando el Ítem se cotice, hay que llevarle
/// al Cliente para que confirme.
class EditarObservacionDialog extends ConsumerStatefulWidget {
  const EditarObservacionDialog({super.key, required this.ordenTrabajoId, required this.itemId, this.observacionActual});

  final String ordenTrabajoId;
  final String itemId;
  final String? observacionActual;

  @override
  ConsumerState<EditarObservacionDialog> createState() => _EditarObservacionDialogState();
}

class _EditarObservacionDialogState extends ConsumerState<EditarObservacionDialog> {
  late final _controller = TextEditingController(text: widget.observacionActual ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });

    final texto = _controller.text.trim();
    final ok = await ref
        .read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId).notifier)
        .editarObservacionItem(itemId: widget.itemId, observacion: texto.isEmpty ? null : texto);

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
    return AlertDialog(
      title: const Text('Observación'),
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
              key: const Key('editarObservacionTexto'),
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Qué se está investigando, a quién contactar, etc.'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('editarObservacionGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
