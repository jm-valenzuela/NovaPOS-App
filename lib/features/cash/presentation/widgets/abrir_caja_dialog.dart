import 'package:flutter/material.dart';

import '../../../../core/utils/formateador_miles.dart';

/// Apertura explícita de Caja con monto inicial declarado (ver
/// SesionCaja.Abrir en el backend) — bloquea la entrada al POS hasta que
/// se declare cuánto efectivo hay al empezar el turno.
class AbrirCajaDialog extends StatefulWidget {
  const AbrirCajaDialog({super.key, required this.nombreCaja});

  final String nombreCaja;

  @override
  State<AbrirCajaDialog> createState() => _AbrirCajaDialogState();
}

class _AbrirCajaDialogState extends State<AbrirCajaDialog> {
  final _controller = TextEditingController(text: '0');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = FormateadorMiles.desformatear(_controller.text);
    if (monto < 0) {
      setState(() => _error = 'Ingresa un monto inicial válido');
      return;
    }
    Navigator.of(context).pop(monto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Abrir ${widget.nombreCaja}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Declara el efectivo con el que empieza el turno antes de vender (puede ser \$0).'),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('abrirCajaMontoInicial'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMiles()],
            decoration: const InputDecoration(labelText: 'Monto inicial', prefixText: '\$ '),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('abrirCajaCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('abrirCajaConfirmar'),
          onPressed: _confirmar,
          child: const Text('Abrir Caja'),
        ),
      ],
    );
  }
}
