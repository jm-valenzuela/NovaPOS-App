import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/nueva_orden_compra_dialog.dart';

class OrdenesCompraScreen extends ConsumerWidget {
  const OrdenesCompraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(ordenesCompraProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de Compra')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevaOrdenCompraBoton'),
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
                    onSelected: (_) => ref.read(ordenesCompraProvider.notifier).cargar(limpiarFiltro: true),
                  ),
                  for (final valor in EstadoOrdenCompra.values)
                    ChoiceChip(
                      key: Key('filtroEstado_${valor.name}'),
                      label: Text(valor.etiqueta),
                      selected: estado.filtroEstado == valor,
                      onSelected: (_) => ref.read(ordenesCompraProvider.notifier).cargar(filtroEstado: valor),
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
                    ? const Center(child: Text('Sin Órdenes de Compra'))
                    : ListView.separated(
                        itemCount: estado.ordenes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final orden = estado.ordenes[index];
                          return ListTile(
                            key: Key('ordenCompra_${orden.id}'),
                            title: Text(orden.proveedorNombre),
                            subtitle: Text('${orden.estado.etiqueta} · ${orden.fechaCreacionOrden.toLocal().toString().split(' ').first}'),
                            trailing: Text(MonedaFormatter.formatear(orden.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () => context.push('/compras/ordenes/${orden.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearOrden(BuildContext context, WidgetRef ref) async {
    final ordenCompraId = await showDialog<String>(context: context, builder: (_) => const NuevaOrdenCompraDialog());
    if (ordenCompraId == null || !context.mounted) return;
    context.push('/compras/ordenes/$ordenCompraId');
    ref.read(ordenesCompraProvider.notifier).cargar();
  }
}
