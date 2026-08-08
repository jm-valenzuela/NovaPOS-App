import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/plazo_pago.dart';
import '../providers/customer_admin_providers.dart';
import '../widgets/crear_plazo_pago_dialog.dart';

/// Mantención del catálogo de Plazos de Pago de Clientes — usado desde
/// ClienteFormDialog y SolicitarCreditoDialog (dropdown de Plazos activos).
/// Un Plazo desactivado sigue existiendo para quien ya lo tiene asignado,
/// solo desaparece del selector de alta/edición nuevas.
class PlazosPagoScreen extends ConsumerWidget {
  const PlazosPagoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(plazosPagoProvider);
    final controller = ref.read(plazosPagoProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Plazos de Pago')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoPlazoPagoBoton'),
        onPressed: () => showDialog<bool>(context: context, builder: (_) => const CrearPlazoPagoDialog()),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: estado.cargando && estado.plazos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.plazos.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Sin Plazos de Pago — crea uno con el botón +.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.plazos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final plazo = estado.plazos[index];
                      return _TarjetaPlazoPago(
                        plazo: plazo,
                        onActivar: () => controller.activar(plazo.id),
                        onDesactivar: () => controller.desactivar(plazo.id),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaPlazoPago extends StatelessWidget {
  const _TarjetaPlazoPago({required this.plazo, required this.onActivar, required this.onDesactivar});

  final PlazoPago plazo;
  final VoidCallback onActivar;
  final VoidCallback onDesactivar;

  @override
  Widget build(BuildContext context) {
    final dias = plazo.cuotas.map((c) => '${c.diasVencimiento}').join('-');
    return Card(
      key: Key('plazoPago_${plazo.id}'),
      child: ListTile(
        title: Text(plazo.nombre),
        subtitle: Text(plazo.cuotas.length == 1 ? '$dias días' : '$dias días (${plazo.cuotas.length} cuotas)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(plazo.activo ? 'Activo' : 'Inactivo'),
              backgroundColor: plazo.activo
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
            const SizedBox(width: 4),
            IconButton(
              key: Key('plazoPagoToggle_${plazo.id}'),
              icon: Icon(plazo.activo ? Icons.toggle_on : Icons.toggle_off_outlined),
              tooltip: plazo.activo ? 'Desactivar' : 'Activar',
              onPressed: plazo.activo ? onDesactivar : onActivar,
            ),
          ],
        ),
      ),
    );
  }
}
