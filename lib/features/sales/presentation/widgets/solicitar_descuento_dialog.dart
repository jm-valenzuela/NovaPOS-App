import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formateador_miles.dart';

enum _TipoDescuento { porcentaje, monto }

/// Resultado de SolicitarDescuentoDialog — mutuamente excluyentes, exactamente
/// uno de los dos viene no-nulo.
class DescuentoSolicitado {
  const DescuentoSolicitado({this.porcentaje, this.monto});

  final double? porcentaje;
  final double? monto;
}

/// El Cajero elige % o $ y tipea el valor — el Supervisor lo autoriza
/// después desde otra pantalla (ver DescuentosPendientesScreen), acá solo
/// se arma la solicitud.
class SolicitarDescuentoDialog extends StatefulWidget {
  const SolicitarDescuentoDialog({super.key});

  @override
  State<SolicitarDescuentoDialog> createState() => _SolicitarDescuentoDialogState();
}

class _SolicitarDescuentoDialogState extends State<SolicitarDescuentoDialog> {
  _TipoDescuento _tipo = _TipoDescuento.porcentaje;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _valorIngresado => _tipo == _TipoDescuento.monto
      ? FormateadorMiles.desformatear(_controller.text)
      : double.tryParse(_controller.text.replaceAll(',', '.'));

  void _confirmar() {
    final valor = _valorIngresado;
    if (valor == null || valor <= 0) {
      setState(() => _error = 'Ingresa un valor mayor a cero');
      return;
    }
    if (_tipo == _TipoDescuento.porcentaje && valor > 100) {
      setState(() => _error = 'El porcentaje no puede ser mayor a 100');
      return;
    }

    Navigator.of(context).pop(
      _tipo == _TipoDescuento.porcentaje
          ? DescuentoSolicitado(porcentaje: valor)
          : DescuentoSolicitado(monto: valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar descuento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Un Supervisor deberá autorizarlo antes de poder cobrar.'),
          const SizedBox(height: 16),
          SegmentedButton<_TipoDescuento>(
            key: const Key('solicitarDescuentoTipo'),
            segments: const [
              ButtonSegment(value: _TipoDescuento.porcentaje, label: Text('Porcentaje')),
              ButtonSegment(value: _TipoDescuento.monto, label: Text('Monto (\$)')),
            ],
            selected: {_tipo},
            onSelectionChanged: (seleccion) => setState(() {
              _tipo = seleccion.first;
              _error = null;
              _controller.clear();
            }),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('solicitarDescuentoValor'),
            controller: _controller,
            autofocus: true,
            keyboardType: _tipo == _TipoDescuento.monto ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _tipo == _TipoDescuento.monto
                ? [FormateadorMiles()]
                : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: _tipo == _TipoDescuento.porcentaje ? 'Porcentaje de descuento' : 'Monto de descuento',
              suffixText: _tipo == _TipoDescuento.porcentaje ? '%' : r'$',
            ),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('solicitarDescuentoCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('solicitarDescuentoConfirmar'),
          onPressed: _confirmar,
          child: const Text('Solicitar'),
        ),
      ],
    );
  }
}
