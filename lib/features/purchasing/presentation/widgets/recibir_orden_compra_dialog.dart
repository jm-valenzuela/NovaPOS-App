import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/orden_compra.dart';
import '../providers/purchasing_providers.dart';

/// Una línea con cantidad 0 (o vacía) simplemente no se manda — permite
/// recepción parcial marcando solo lo que efectivamente llegó en esta
/// entrega, dejando el resto pendiente para una recepción posterior (ver
/// OrdenCompra.Recibir en el backend, que acepta llamadas repetidas).
class RecibirOrdenCompraDialog extends ConsumerStatefulWidget {
  const RecibirOrdenCompraDialog({super.key, required this.ordenCompraId, required this.lineasPendientes});

  final String ordenCompraId;
  final List<LineaOrdenCompra> lineasPendientes;

  @override
  ConsumerState<RecibirOrdenCompraDialog> createState() => _RecibirOrdenCompraDialogState();
}

class _RecibirOrdenCompraDialogState extends ConsumerState<RecibirOrdenCompraDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final linea in widget.lineasPendientes) linea.varianteProductoId: TextEditingController(text: linea.cantidadPendiente.toString()),
  };
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recibir mercadería'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              const Text('Cantidad recibida ahora — deja en 0 lo que no llegó todavía.'),
              const SizedBox(height: 12),
              for (final linea in widget.lineasPendientes) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text('${linea.nombreProducto} (pendiente: ${_formatearCantidad(linea.cantidadPendiente)})'),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        key: Key('recibirCantidad_${linea.varianteProductoId}'),
                        controller: _controllers[linea.varianteProductoId],
                        decoration: const InputDecoration(isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('recibirConfirmar'),
          onPressed: _guardando ? null : _confirmar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirmar recepción'),
        ),
      ],
    );
  }

  static String _formatearCantidad(double cantidad) =>
      cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();

  Future<void> _confirmar() async {
    final lineas = <String, double>{};
    for (final entry in _controllers.entries) {
      final cantidad = double.tryParse(entry.value.text.trim()) ?? 0;
      if (cantidad > 0) lineas[entry.key] = cantidad;
    }

    if (lineas.isEmpty) {
      setState(() => _error = 'Ingresa al menos una cantidad recibida mayor a cero.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(ordenCompraDetalleProvider(widget.ordenCompraId).notifier).recibir(lineas);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(ordenCompraDetalleProvider(widget.ordenCompraId)).error ?? 'No se pudo registrar la recepción.';
      });
    }
  }
}
