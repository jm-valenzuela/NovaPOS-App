import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../providers/inventory_providers.dart';
import '../widgets/nuevo_traslado_dialog.dart';

String _nombreBodega(List<BodegaResumen> bodegas, String bodegaId) {
  for (final bodega in bodegas) {
    if (bodega.bodegaId == bodegaId) return bodega.nombreBodega;
  }
  return bodegaId;
}

/// Listado de Traslados — filtrable por Bodega (origen o destino), más
/// reciente primero (ya viene ordenado del backend).
class TrasladosInventarioScreen extends ConsumerWidget {
  const TrasladosInventarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(trasladosProvider);
    final bodegasAsync = ref.watch(bodegasInventarioProvider);
    final bodegas = bodegasAsync.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Traslados de Inventario')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoTrasladoBoton'),
        onPressed: () => _crearTraslado(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (bodegas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('filtroBodegaTrasladoTodas'),
                      label: const Text('Todas las Bodegas'),
                      selected: estado.filtroBodegaId == null,
                      onSelected: (_) => ref.read(trasladosProvider.notifier).cargar(limpiarFiltroBodega: true),
                    ),
                    for (final bodega in bodegas)
                      ChoiceChip(
                        key: Key('filtroBodegaTraslado_${bodega.bodegaId}'),
                        label: Text(bodega.nombreBodega),
                        selected: estado.filtroBodegaId == bodega.bodegaId,
                        onSelected: (_) => ref.read(trasladosProvider.notifier).cargar(filtroBodegaId: bodega.bodegaId),
                      ),
                  ],
                ),
              ),
            ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: estado.cargando
                ? const Center(child: CircularProgressIndicator())
                : estado.traslados.isEmpty
                    ? const Center(child: Text('Sin Traslados'))
                    : ListView.separated(
                        itemCount: estado.traslados.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final traslado = estado.traslados[index];
                          return ListTile(
                            key: Key('traslado_${traslado.id}'),
                            leading: const Icon(Icons.swap_horiz),
                            title: Text(
                              '${_nombreBodega(bodegas, traslado.bodegaOrigenId)} → ${_nombreBodega(bodegas, traslado.bodegaDestinoId)}',
                            ),
                            subtitle: Text(
                              '${traslado.estado.etiqueta} · ${traslado.cantidadLineas} línea(s) · ${traslado.fechaCreacion.toLocal().toString().split(' ').first}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/inventario/traslados/${traslado.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearTraslado(BuildContext context, WidgetRef ref) async {
    final trasladoId = await showDialog<String>(context: context, builder: (_) => const NuevoTrasladoDialog());
    if (trasladoId == null || !context.mounted) return;
    context.push('/inventario/traslados/$trasladoId');
    ref.read(trasladosProvider.notifier).cargar();
  }
}
