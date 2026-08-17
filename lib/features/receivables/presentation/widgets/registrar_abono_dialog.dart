import 'package:flutter/material.dart';

import '../../../../core/utils/formateador_miles.dart';
import '../../../sales/domain/models/venta_enums.dart';

class AbonoSolicitado {
  const AbonoSolicitado({required this.monto, required this.medioPago, this.motivo});

  final double monto;
  final MedioPago medioPago;
  final String? motivo;
}

/// Registra un Abono contra el saldo de un Cliente — a diferencia del
/// pago mixto de CheckoutDialog (varias líneas), acá un solo medio de
/// pago alcanza (no se pidió pago dividido para Abonos).
class RegistrarAbonoDialog extends StatefulWidget {
  const RegistrarAbonoDialog({super.key, required this.saldoActual});

  final double saldoActual;

  @override
  State<RegistrarAbonoDialog> createState() => _RegistrarAbonoDialogState();
}

class _RegistrarAbonoDialogState extends State<RegistrarAbonoDialog> {
  final _montoController = TextEditingController();
  final _motivoController = TextEditingController();
  MedioPago _medioPago = MedioPago.efectivo;
  String? _error;

  @override
  void dispose() {
    _montoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = FormateadorMiles.desformatear(_montoController.text);
    if (monto <= 0) {
      setState(() => _error = 'Ingresa un monto mayor a cero.');
      return;
    }
    if (monto > widget.saldoActual) {
      setState(() => _error = 'El abono no puede superar el saldo actual.');
      return;
    }

    Navigator.of(context).pop(AbonoSolicitado(
      monto: monto,
      medioPago: _medioPago,
      motivo: _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar abono'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('abonoMonto'),
            controller: _montoController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMiles()],
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MedioPago>(
            key: const Key('abonoMedioPago'),
            value: _medioPago,
            decoration: const InputDecoration(labelText: 'Medio de pago'),
            items: MedioPago.values.map((m) => DropdownMenuItem(value: m, child: Text(m.etiqueta))).toList(),
            onChanged: (valor) => setState(() => _medioPago = valor ?? _medioPago),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('abonoMotivo'),
            controller: _motivoController,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('abonoConfirmar'),
          onPressed: _confirmar,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
