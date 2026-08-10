import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show inventoryRepositoryProvider;
import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../providers/inventory_providers.dart';

/// Elige la Bodega a contar y abre la Toma — devuelve el Id de la Toma
/// creada, o null si se canceló/falló.
class NuevaTomaDialog extends ConsumerStatefulWidget {
  const NuevaTomaDialog({super.key});

  @override
  ConsumerState<NuevaTomaDialog> createState() => _NuevaTomaDialogState();
}

class _NuevaTomaDialogState extends ConsumerState<NuevaTomaDialog> {
  BodegaResumen? _seleccionada;
  bool _creando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bodegasAsync = ref.watch(bodegasInventarioProvider);

    return AlertDialog(
      title: const Text('Nueva Toma de Inventario'),
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
              if (bodegas.isEmpty)
                const Text('La Empresa no tiene ninguna Bodega configurada.')
              else
                DropdownButtonFormField<BodegaResumen>(
                  key: const Key('nuevaTomaBodega'),
                  value: _seleccionada,
                  decoration: const InputDecoration(labelText: 'Bodega'),
                  items: bodegas
                      .map((b) => DropdownMenuItem(value: b, child: Text('${b.nombreBodega} (${b.nombreSucursal})')))
                      .toList(),
                  onChanged: (valor) => setState(() => _seleccionada = valor),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('No se pudieron cargar las Bodegas: $e'),
        ),
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('nuevaTomaConfirmar'),
          onPressed: (_creando || _seleccionada == null) ? null : _crear,
          child: _creando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Abrir'),
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
      final tomaId = await ref.read(inventoryRepositoryProvider).abrirToma(bodegaId: _seleccionada!.bodegaId);
      if (!mounted) return;
      Navigator.of(context).pop(tomaId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creando = false;
        _error = e.toString();
      });
    }
  }
}
