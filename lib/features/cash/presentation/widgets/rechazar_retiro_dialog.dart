import 'package:flutter/material.dart';

/// Motivo obligatorio (ver RetiroCaja.Rechazar en el backend) — queda
/// trazable por qué se rechazó, no es opcional. Mismo patrón que
/// RechazarCreditoDialog en Customers.
class RechazarRetiroDialog extends StatefulWidget {
  const RechazarRetiroDialog({super.key});

  @override
  State<RechazarRetiroDialog> createState() => _RechazarRetiroDialogState();
}

class _RechazarRetiroDialogState extends State<RechazarRetiroDialog> {
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
      title: const Text('Rechazar Retiro de Caja'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('rechazarRetiroMotivo'),
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
          key: const Key('rechazarRetiroCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('rechazarRetiroConfirmar'),
          onPressed: _confirmar,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
