import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cliente_resumen.dart';
import '../../domain/models/plazo_pago.dart';
import '../providers/customer_admin_providers.dart';

/// Dispara la evaluación de Cupo de Crédito para un Cliente — no lo otorga
/// de inmediato, queda Pendiente hasta que alguien con el permiso
/// "customers.clientes.autorizarcredito" lo autorice o rechace desde
/// SolicitudesCreditoPendientesScreen (mismo criterio que el descuento
/// general del POS: quien pide no se autoriza a sí mismo). El backend
/// exige que el Cliente ya tenga RUT — acá se valida antes de intentar,
/// para no hacer una llamada que sabemos que va a fallar.
class SolicitarCreditoDialog extends ConsumerStatefulWidget {
  const SolicitarCreditoDialog({super.key, required this.cliente});

  final ClienteResumen cliente;

  @override
  ConsumerState<SolicitarCreditoDialog> createState() => _SolicitarCreditoDialogState();
}

class _SolicitarCreditoDialogState extends ConsumerState<SolicitarCreditoDialog> {
  final _cupoController = TextEditingController();
  String? _plazoPagoIdSeleccionado;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _cupoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sinRut = widget.cliente.rut == null || widget.cliente.rut!.trim().isEmpty;

    return AlertDialog(
      title: const Text('Solicitar Cupo de Crédito'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.cliente.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (sinRut)
            Text(
              'Este Cliente no tiene RUT registrado — no se puede solicitar crédito hasta completarlo.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            TextField(
              key: const Key('solicitarCreditoCupo'),
              controller: _cupoController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Cupo de crédito solicitado'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            ),
            const SizedBox(height: 12),
            _SelectorPlazoPagoSolicitud(
              plazos: ref.watch(plazosPagoProvider).plazos,
              seleccionado: _plazoPagoIdSeleccionado,
              onChanged: (id) => setState(() => _plazoPagoIdSeleccionado = id),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        if (!sinRut)
          FilledButton(
            key: const Key('solicitarCreditoConfirmar'),
            onPressed: _guardando ? null : _solicitar,
            child: _guardando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Solicitar'),
          ),
      ],
    );
  }

  Future<void> _solicitar() async {
    final cupo = double.tryParse(_cupoController.text.replaceAll(',', '.'));
    if (cupo == null || cupo <= 0) {
      setState(() => _error = 'Ingresa un cupo válido, mayor a 0.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await ref.read(clientesAdminProvider.notifier).solicitarCredito(
            clienteId: widget.cliente.id,
            cupoSolicitado: cupo,
            plazoPagoIdSolicitado: _plazoPagoIdSeleccionado,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }
}

/// Dropdown de Plazos de Pago activos — mismo criterio que
/// _SelectorPlazoPago en ClienteFormDialog (vacío = "Inmediato" es válido),
/// nombre distinto para evitar colisión de símbolos privados entre archivos.
class _SelectorPlazoPagoSolicitud extends StatelessWidget {
  const _SelectorPlazoPagoSolicitud({required this.plazos, required this.seleccionado, required this.onChanged});

  final List<PlazoPago> plazos;
  final String? seleccionado;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final activos = plazos.where((p) => p.activo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: const Key('solicitarCreditoPlazo'),
          value: seleccionado,
          decoration: const InputDecoration(labelText: 'Plazo de pago'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Inmediato')),
            for (final plazo in activos) DropdownMenuItem<String?>(value: plazo.id, child: Text(plazo.nombre)),
          ],
          onChanged: onChanged,
        ),
        if (activos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'No hay Plazos de Pago activos — créalos en Clientes ▸ Plazos de Pago.',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
