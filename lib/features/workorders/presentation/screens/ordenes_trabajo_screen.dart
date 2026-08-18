import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';
import '../widgets/nueva_orden_trabajo_dialog.dart';

class OrdenesTrabajoScreen extends ConsumerWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(ordenesTrabajoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de Trabajo')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevaOrdenTrabajoBoton'),
        onPressed: () => _crearOrden(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('filtroEstadoTodos'),
                    label: const Text('Todas'),
                    selected: estado.filtroEstado == null,
                    onSelected: (_) => ref.read(ordenesTrabajoProvider.notifier).cargar(limpiarFiltro: true),
                  ),
                  for (final valor in EstadoOrdenTrabajo.values)
                    ChoiceChip(
                      key: Key('filtroEstado_${valor.name}'),
                      label: Text(valor.etiqueta),
                      selected: estado.filtroEstado == valor,
                      onSelected: (_) => ref.read(ordenesTrabajoProvider.notifier).cargar(filtroEstado: valor),
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
                : estado.ordenes.isEmpty
                    ? const Center(child: Text('Sin Órdenes de Trabajo'))
                    : ListView.separated(
                        itemCount: estado.ordenes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final orden = estado.ordenes[index];
                          return ListTile(
                            key: Key('ordenTrabajo_${orden.id}'),
                            title: Text('${orden.numero} · ${orden.clienteNombre}'),
                            subtitle: Text(
                              '${orden.estado.etiqueta} · ${orden.fechaRecepcion.toLocal().toString().split(' ').first}\n${orden.descripcion}',
                            ),
                            isThreeLine: true,
                            trailing: orden.montoCotizado == null
                                ? null
                                : Text(MonedaFormatter.formatear(orden.montoCotizado!),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () => context.push('/ordenes-trabajo/${orden.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearOrden(BuildContext context, WidgetRef ref) async {
    final ordenTrabajoId = await showDialog<String>(context: context, builder: (_) => const NuevaOrdenTrabajoDialog());
    if (ordenTrabajoId == null || !context.mounted) return;
    context.push('/ordenes-trabajo/$ordenTrabajoId');
    ref.read(ordenesTrabajoProvider.notifier).cargar();
  }
}
