import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';
import '../widgets/crear_operario_dialog.dart';

/// Administración de Operarios (Usuarios reales del sistema, ver
/// CrearOperarioDialog) — listado con activos e inactivos, alta y baja, y
/// "Revisar lo asignado": qué Ítems abiertos tiene cada uno ahora mismo.
class OperariosScreen extends ConsumerWidget {
  const OperariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(operariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operarios'),
        actions: [
          IconButton(
            key: const Key('operariosVerCargaBoton'),
            tooltip: 'Revisar lo asignado',
            icon: const Icon(Icons.checklist_outlined),
            onPressed: () => _verCarga(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('operariosNuevoBoton'),
        onPressed: () => showDialog<bool>(context: context, builder: (_) => const CrearOperarioDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Operario'),
      ),
      body: estado.cargando && estado.operarios.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : estado.operarios.isEmpty
              ? const Center(child: Text('Sin Operarios todavía.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: estado.operarios.length,
                  itemBuilder: (context, indice) {
                    final operario = estado.operarios[indice];
                    return Card(
                      key: Key('operario_${operario.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(operario.nombreCompleto),
                        subtitle: Text('${operario.email}${operario.rolesNombres.isNotEmpty ? ' · ${operario.rolesNombres.join(', ')}' : ''}'),
                        trailing: operario.activo
                            ? OutlinedButton(
                                key: Key('operarioDesactivar_${operario.id}'),
                                onPressed: () => _desactivar(context, ref, operario),
                                child: const Text('Desactivar'),
                              )
                            : const Chip(label: Text('Inactivo')),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _desactivar(BuildContext context, WidgetRef ref, UsuarioResumen operario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar Operario'),
        content: Text('¿Desactivar a "${operario.nombreCompleto}"? No podrá volver a loguearse ni ser asignado a nuevos Ítems.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('confirmarDesactivarOperario'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await ref.read(operariosProvider.notifier).desactivar(operario.id);
  }

  Future<void> _verCarga(BuildContext context) async {
    await showDialog<void>(context: context, builder: (_) => const _CargaOperariosDialog());
  }
}

class _CargaOperariosDialog extends ConsumerWidget {
  const _CargaOperariosDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carga = ref.watch(cargaOperariosProvider);

    return AlertDialog(
      title: const Text('Revisar lo asignado'),
      content: SizedBox(
        width: 480,
        child: carga.when(
          data: (operarios) => operarios.isEmpty
              ? const Text('Ningún Operario tiene Ítems abiertos asignados ahora mismo.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final operario in operarios) ...[
                        Text(operario.nombreCompleto, style: Theme.of(context).textTheme.titleSmall),
                        for (final item in operario.items)
                          ListTile(
                            key: Key('cargaItem_${item.itemId}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.descripcion),
                            subtitle: Text('${item.numeroOrdenTrabajo} · ${item.estado.etiqueta}'),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push('/ordenes-trabajo/${item.ordenTrabajoId}');
                            },
                          ),
                        const Divider(),
                      ],
                    ],
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('No se pudo cargar. $e'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
