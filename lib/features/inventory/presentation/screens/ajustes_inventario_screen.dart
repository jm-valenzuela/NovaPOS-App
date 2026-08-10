import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../../domain/models/inventory_enums.dart';
import '../providers/inventory_providers.dart';
import '../widgets/nueva_toma_dialog.dart';

String _nombreBodega(List<BodegaResumen> bodegas, String bodegaId) {
  for (final bodega in bodegas) {
    if (bodega.bodegaId == bodegaId) return bodega.nombreBodega;
  }
  return bodegaId;
}

/// Listado de Tomas de Inventario (Ajustes) — filtrable por Bodega, más
/// reciente primero (ya viene ordenado del backend).
class AjustesInventarioScreen extends ConsumerWidget {
  const AjustesInventarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(tomasInventarioProvider);
    final bodegasAsync = ref.watch(bodegasInventarioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de Inventario')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevaTomaBoton'),
        onPressed: () => _abrirToma(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          bodegasAsync.when(
            data: (bodegas) => bodegas.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            key: const Key('filtroBodegaTodas'),
                            label: const Text('Todas las Bodegas'),
                            selected: estado.filtroBodegaId == null,
                            onSelected: (_) => ref.read(tomasInventarioProvider.notifier).cargar(limpiarFiltroBodega: true),
                          ),
                          for (final bodega in bodegas)
                            ChoiceChip(
                              key: Key('filtroBodega_${bodega.bodegaId}'),
                              label: Text(bodega.nombreBodega),
                              selected: estado.filtroBodegaId == bodega.bodegaId,
                              onSelected: (_) => ref.read(tomasInventarioProvider.notifier).cargar(filtroBodegaId: bodega.bodegaId),
                            ),
                        ],
                      ),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: estado.cargando
                ? const Center(child: CircularProgressIndicator())
                : estado.tomas.isEmpty
                    ? const Center(child: Text('Sin Tomas de Inventario'))
                    : ListView.separated(
                        itemCount: estado.tomas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final toma = estado.tomas[index];
                          final abierta = toma.estado == EstadoTomaInventario.abierta;
                          final nombreBodega = _nombreBodega(bodegasAsync.valueOrNull ?? const [], toma.bodegaId);
                          return ListTile(
                            key: Key('toma_${toma.id}'),
                            leading: Icon(abierta ? Icons.pending_actions : Icons.check_circle_outline,
                                color: abierta ? Theme.of(context).colorScheme.primary : null),
                            title: Text('$nombreBodega · ${toma.estado.etiqueta}'),
                            subtitle: Text(
                                '${toma.cantidadLineas} línea(s) · ${toma.fechaApertura.toLocal().toString().split(' ').first}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/inventario/ajustes/${toma.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirToma(BuildContext context, WidgetRef ref) async {
    final tomaId = await showDialog<String>(context: context, builder: (_) => const NuevaTomaDialog());
    if (tomaId == null || !context.mounted) return;
    context.push('/inventario/ajustes/$tomaId');
    ref.read(tomasInventarioProvider.notifier).cargar();
  }
}
