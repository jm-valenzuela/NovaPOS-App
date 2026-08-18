import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workorders_providers.dart';

/// Rechazar un Ítem puntual — no cancela la Orden completa, los demás
/// Ítems siguen su curso (ver ItemOrdenTrabajo.Rechazar en el backend).
class RechazarItemDialog extends ConsumerStatefulWidget {
  const RechazarItemDialog({super.key, required this.ordenTrabajoId, required this.itemId, required this.descripcionItem});

  final String ordenTrabajoId;
  final String itemId;
  final String descripcionItem;

  @override
  ConsumerState<RechazarItemDialog> createState() => _RechazarItemDialogState();
}

class _RechazarItemDialogState extends ConsumerState<RechazarItemDialog> {
  final _motivoController = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _rechazar() async {
    final motivo = _motivoController.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });

    final ok = await ref
        .read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId).notifier)
        .rechazarItem(itemId: widget.itemId, motivo: motivo.isEmpty ? null : motivo);

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
      title: Text('Rechazar: ${widget.descripcionItem}'),
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
              key: const Key('rechazarItemMotivo'),
              controller: _motivoController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Motivo del rechazo (opcional)'),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('rechazarItemConfirmar'),
          onPressed: _guardando ? null : _rechazar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Rechazar'),
        ),
      ],
    );
  }
}
