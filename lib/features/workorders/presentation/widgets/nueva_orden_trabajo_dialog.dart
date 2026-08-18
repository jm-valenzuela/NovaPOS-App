import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show tenancyRepositoryProvider;
import '../../../sales/presentation/widgets/selector_cliente_dialog.dart';
import '../providers/workorders_providers.dart';

/// Elige Cliente (obligatorio — a diferencia del POS, acá no existe
/// "Cliente Genérico": una Orden de Trabajo siempre es nominativa) y
/// describe el problema/trabajo a recibir. La Caja se resuelve sola (la
/// primera de la Empresa, ver SucursalId derivado de CajaId en el
/// backend) — mismo criterio que NuevaOrdenCompraDialog para la Bodega.
/// Devuelve el Id de la Orden creada, o null si se canceló/falló.
class NuevaOrdenTrabajoDialog extends ConsumerStatefulWidget {
  const NuevaOrdenTrabajoDialog({super.key});

  @override
  ConsumerState<NuevaOrdenTrabajoDialog> createState() => _NuevaOrdenTrabajoDialogState();
}

class _NuevaOrdenTrabajoDialogState extends ConsumerState<NuevaOrdenTrabajoDialog> {
  final _descripcionController = TextEditingController();
  ClienteResumen? _cliente;
  bool _creando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _elegirCliente() async {
    final elegido = await showDialog<ClienteResumen>(
      context: context,
      builder: (_) => const SelectorClienteDialog(permitirClienteGenerico: false),
    );
    if (elegido == null || !mounted) return;
    setState(() => _cliente = elegido);
  }

  void _verHistorial() {
    final cliente = _cliente;
    if (cliente == null) return;
    Navigator.of(context).pop();
    context.push('/ordenes-trabajo/historial/${cliente.id}', extra: cliente.nombre);
  }

  Future<void> _crear() async {
    final cliente = _cliente;
    if (cliente == null || _descripcionController.text.trim().isEmpty) return;

    setState(() {
      _creando = true;
      _error = null;
    });

    try {
      final cajas = await ref.read(tenancyRepositoryProvider).listarCajas();
      if (cajas.isEmpty) throw Exception('La Empresa no tiene ninguna Caja/Sucursal configurada.');

      final ordenTrabajoId = await ref.read(workOrdersRepositoryProvider).recibir(
            cajaId: cajas.first.cajaId,
            clienteId: cliente.id,
            descripcion: _descripcionController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(ordenTrabajoId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeCrear = _cliente != null && _descripcionController.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Nueva Orden de Trabajo'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (_cliente == null)
                OutlinedButton.icon(
                  key: const Key('nuevaOtElegirCliente'),
                  onPressed: _elegirCliente,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Elegir Cliente'),
                )
              else ...[
                ListTile(
                  key: const Key('nuevaOtClienteElegido'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(_cliente!.nombre),
                  subtitle: Text(_cliente!.rut ?? 'Sin RUT'),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _cliente = null)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('nuevaOtVerHistorial'),
                    onPressed: _creando ? null : _verHistorial,
                    icon: const Icon(Icons.history),
                    label: const Text('Ver historial de este Cliente'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                key: const Key('nuevaOtDescripcion'),
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción del trabajo o problema reportado'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('nuevaOtConfirmar'),
          onPressed: (_creando || !puedeCrear) ? null : _crear,
          child: _creando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Recibir'),
        ),
      ],
    );
  }
}
