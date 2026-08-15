import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/retiro_caja_pendiente.dart';
import '../providers/cash_providers.dart';
import '../widgets/rechazar_retiro_dialog.dart';

/// Pantalla de quien autoriza Retiros de Caja (permiso
/// "cash.retiros.autorizar") — mismo patrón que
/// SolicitudesCreditoPendientesScreen: sirve tanto si está parado junto al
/// Cajero que pidió el retiro como si está en la oficina.
class RetirosPendientesScreen extends ConsumerWidget {
  const RetirosPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(retirosPendientesProvider);
    final controller = ref.read(retirosPendientesProvider.notifier);

    ref.listen(retirosPendientesProvider, (anterior, actual) {
      if (actual.error != null && actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actual.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Retiros de Caja Pendientes')),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: estado.cargando && estado.pendientes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.pendientes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No hay Retiros de Caja pendientes.')),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.pendientes.length,
                    itemBuilder: (context, index) {
                      final pendiente = estado.pendientes[index];
                      final procesando = estado.procesando.contains(pendiente.id);
                      return _TarjetaRetiroPendiente(
                        pendiente: pendiente,
                        procesando: procesando,
                        onAutorizar: () => controller.autorizar(pendiente.id),
                        onRechazar: () async {
                          final motivo = await showDialog<String>(
                            context: context,
                            builder: (_) => const RechazarRetiroDialog(),
                          );
                          if (motivo != null) await controller.rechazar(pendiente.id, motivo);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaRetiroPendiente extends StatelessWidget {
  const _TarjetaRetiroPendiente({
    required this.pendiente,
    required this.procesando,
    required this.onAutorizar,
    required this.onRechazar,
  });

  final RetiroCajaPendiente pendiente;
  final bool procesando;
  final VoidCallback onAutorizar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MonedaFormatter.formatear(pendiente.monto), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(pendiente.motivo),
            const SizedBox(height: 4),
            Text(
              'Solicitado ${pendiente.fechaSolicitud.toLocal().toString().split('.').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('retiroPendienteRechazar_${pendiente.id}'),
                    onPressed: procesando ? null : onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('retiroPendienteAutorizar_${pendiente.id}'),
                    onPressed: procesando ? null : onAutorizar,
                    child: procesando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Autorizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
