import 'package:flutter/material.dart';

import '../../../../core/utils/formateador_miles.dart';

/// Solicitar un Retiro de efectivo de la Caja — queda Pendiente hasta que
/// un Supervisor lo autorice (ver "cash.retiros.autorizar", quien pide no
/// puede autorizarse a sí mismo).
class RetirarEfectivoDialog extends StatefulWidget {
  const RetirarEfectivoDialog({super.key});

  @override
  State<RetirarEfectivoDialog> createState() => _RetirarEfectivoDialogState();
}

class _RetirarEfectivoDialogState extends State<RetirarEfectivoDialog> {
  final _montoController = TextEditingController();
  final _motivoController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _montoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = FormateadorMiles.desformatear(_montoController.text);
    final motivo = _motivoController.text.trim();
    if (monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    if (motivo.isEmpty) {
      setState(() => _error = 'El motivo es obligatorio');
      return;
    }
    Navigator.of(context).pop((monto: monto, motivo: motivo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retirar efectivo de Caja'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('retirarEfectivoMonto'),
            controller: _montoController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMiles()],
            decoration: const InputDecoration(labelText: 'Monto a retirar', prefixText: '\$ '),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('retirarEfectivoMotivo'),
            controller: _motivoController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo'),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('retirarEfectivoCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('retirarEfectivoConfirmar'),
          onPressed: _confirmar,
          child: const Text('Solicitar Retiro'),
        ),
      ],
    );
  }
}
