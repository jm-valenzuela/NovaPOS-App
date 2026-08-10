import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../sales/domain/models/venta_enums.dart';

class PagoSolicitado {
  const PagoSolicitado({required this.monto, required this.medioPago, this.motivo});

  final double monto;
  final MedioPago medioPago;
  final String? motivo;
}

/// Registra un pago (Abono) contra el saldo de un Proveedor — espejo de
/// RegistrarAbonoDialog (Receivables), un solo medio de pago alcanza (no
/// se pidió pago dividido para Abonos).
class RegistrarPagoDialog extends StatefulWidget {
  const RegistrarPagoDialog({super.key, required this.saldoActual});

  final double saldoActual;

  @override
  State<RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<RegistrarPagoDialog> {
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
    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto mayor a cero.');
      return;
    }
    if (monto > widget.saldoActual) {
      setState(() => _error = 'El pago no puede superar el saldo actual.');
      return;
    }

    Navigator.of(context).pop(PagoSolicitado(
      monto: monto,
      medioPago: _medioPago,
      motivo: _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('pagoMonto'),
            controller: _montoController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MedioPago>(
            key: const Key('pagoMedioPago'),
            value: _medioPago,
            decoration: const InputDecoration(labelText: 'Medio de pago'),
            items: MedioPago.values.map((m) => DropdownMenuItem(value: m, child: Text(m.etiqueta))).toList(),
            onChanged: (valor) => setState(() => _medioPago = valor ?? _medioPago),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('pagoMotivo'),
            controller: _motivoController,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('pagoConfirmar'),
          onPressed: _confirmar,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
