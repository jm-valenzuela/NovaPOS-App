import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formateador_miles.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';
import 'representacion_impresa_anticipo.dart';

/// Registra dinero recibido por adelantado (ej. para comprarle a un
/// Proveedor) — exige una Sesión de Caja Abierta (ya resuelta por quien
/// llama, ver _registrarAnticipo en orden_trabajo_detalle_screen.dart) y
/// no permite superar el saldo pendiente. No genera Boleta/Factura, solo
/// un comprobante de pago interno impreso al confirmar.
class RegistrarAnticipoDialog extends ConsumerStatefulWidget {
  const RegistrarAnticipoDialog({
    super.key,
    required this.ordenTrabajoId,
    required this.sesionCajaId,
    required this.numeroOrden,
    required this.clienteNombre,
    required this.saldoDisponible,
  });

  final String ordenTrabajoId;
  final String sesionCajaId;
  final String numeroOrden;
  final String clienteNombre;
  final double saldoDisponible;

  @override
  ConsumerState<RegistrarAnticipoDialog> createState() => _RegistrarAnticipoDialogState();
}

class _RegistrarAnticipoDialogState extends ConsumerState<RegistrarAnticipoDialog> {
  final _montoController = TextEditingController();
  MedioPagoAnticipo _medioPago = MedioPagoAnticipo.efectivo;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final monto = FormateadorMiles.desformatear(_montoController.text);

    if (monto <= 0) {
      setState(() => _error = 'Ingresa un monto mayor a cero.');
      return;
    }
    if (monto > widget.saldoDisponible) {
      setState(() => _error = 'El Anticipo no puede superar el saldo pendiente (${MonedaFormatter.formatear(widget.saldoDisponible)}).');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final ok = await ref.read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId).notifier).registrarAnticipo(
          sesionCajaId: widget.sesionCajaId,
          monto: monto,
          medioPago: _medioPago,
        );

    if (!mounted) return;
    if (ok) {
      await imprimirComprobanteAnticipo(
        numeroOrden: widget.numeroOrden,
        clienteNombre: widget.clienteNombre,
        monto: monto,
        medioPago: _medioPago,
        fecha: DateTime.now(),
      );
      if (!mounted) return;
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
      title: const Text('Registrar Anticipo'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo pendiente: ${MonedaFormatter.formatear(widget.saldoDisponible)}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            TextField(
              key: const Key('anticipoMonto'),
              controller: _montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMiles()],
              decoration: const InputDecoration(labelText: 'Monto'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MedioPagoAnticipo>(
              key: const Key('anticipoMedioPago'),
              value: _medioPago,
              decoration: const InputDecoration(labelText: 'Medio de pago'),
              items: [for (final m in MedioPagoAnticipo.values) DropdownMenuItem(value: m, child: Text(m.etiqueta))],
              onChanged: _guardando ? null : (m) => setState(() => _medioPago = m ?? MedioPagoAnticipo.efectivo),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('anticipoConfirmar'),
          onPressed: _guardando ? null : _registrar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
