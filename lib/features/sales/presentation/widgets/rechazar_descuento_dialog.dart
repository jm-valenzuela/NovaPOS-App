import 'package:flutter/material.dart';

/// Motivo obligatorio (ver Venta.RechazarDescuentoGeneral en el backend) —
/// queda trazable por qué se rechazó, no es opcional.
class RechazarDescuentoDialog extends StatefulWidget {
  const RechazarDescuentoDialog({super.key});

  @override
  State<RechazarDescuentoDialog> createState() => _RechazarDescuentoDialogState();
}

class _RechazarDescuentoDialogState extends State<RechazarDescuentoDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final motivo = _controller.text.trim();
    if (motivo.isEmpty) {
      setState(() => _error = 'El motivo es obligatorio');
      return;
    }
    Navigator.of(context).pop(motivo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar descuento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('rechazarDescuentoMotivo'),
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo'),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('rechazarDescuentoCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('rechazarDescuentoConfirmar'),
          onPressed: _confirmar,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
