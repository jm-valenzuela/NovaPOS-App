import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show inventoryRepositoryProvider;
import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../providers/inventory_providers.dart';

/// Elige Bodega origen y destino y crea el Traslado — devuelve el Id del
/// Traslado creado, o null si se canceló/falló.
class NuevoTrasladoDialog extends ConsumerStatefulWidget {
  const NuevoTrasladoDialog({super.key});

  @override
  ConsumerState<NuevoTrasladoDialog> createState() => _NuevoTrasladoDialogState();
}

class _NuevoTrasladoDialogState extends ConsumerState<NuevoTrasladoDialog> {
  BodegaResumen? _origen;
  BodegaResumen? _destino;
  bool _creando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bodegasAsync = ref.watch(bodegasInventarioProvider);

    return AlertDialog(
      title: const Text('Nuevo Traslado'),
      content: SizedBox(
        width: 380,
        child: bodegasAsync.when(
          data: (bodegas) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (bodegas.length < 2)
                const Text('Se necesitan al menos dos Bodegas configuradas para trasladar mercadería.')
              else ...[
                DropdownButtonFormField<BodegaResumen>(
                  key: const Key('nuevoTrasladoOrigen'),
                  value: _origen,
                  decoration: const InputDecoration(labelText: 'Bodega origen'),
                  items: bodegas
                      .map((b) => DropdownMenuItem(value: b, child: Text('${b.nombreBodega} (${b.nombreSucursal})')))
                      .toList(),
                  onChanged: (valor) => setState(() => _origen = valor),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BodegaResumen>(
                  key: const Key('nuevoTrasladoDestino'),
                  value: _destino,
                  decoration: const InputDecoration(labelText: 'Bodega destino'),
                  items: bodegas
                      .where((b) => b.bodegaId != _origen?.bodegaId)
                      .map((b) => DropdownMenuItem(value: b, child: Text('${b.nombreBodega} (${b.nombreSucursal})')))
                      .toList(),
                  onChanged: (valor) => setState(() => _destino = valor),
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('No se pudieron cargar las Bodegas: $e'),
        ),
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('nuevoTrasladoConfirmar'),
          onPressed: (_creando || _origen == null || _destino == null) ? null : _crear,
          child: _creando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _crear() async {
    setState(() {
      _creando = true;
      _error = null;
    });

    try {
      final trasladoId = await ref
          .read(inventoryRepositoryProvider)
          .crearTraslado(bodegaOrigenId: _origen!.bodegaId, bodegaDestinoId: _destino!.bodegaId);
      if (!mounted) return;
      Navigator.of(context).pop(trasladoId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creando = false;
        _error = e.toString();
      });
    }
  }
}
