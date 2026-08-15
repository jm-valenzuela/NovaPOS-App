import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/plazo_pago.dart';
import '../../domain/models/solicitud_credito_pendiente.dart';
import '../providers/customer_admin_providers.dart' show plazosPagoProvider;
import '../providers/solicitudes_credito_pendientes_providers.dart';
import '../widgets/rechazar_credito_dialog.dart';

/// Pantalla de quien autoriza Cupo de Crédito (permiso
/// "customers.clientes.autorizarcredito") — mismo patrón que
/// DescuentosPendientesScreen: sirve tanto si está parado junto a quien
/// registró al Cliente como si está en la oficina.
class SolicitudesCreditoPendientesScreen extends ConsumerWidget {
  const SolicitudesCreditoPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(solicitudesCreditoPendientesProvider);
    final controller = ref.read(solicitudesCreditoPendientesProvider.notifier);
    final plazos = ref.watch(plazosPagoProvider).plazos;

    ref.listen(solicitudesCreditoPendientesProvider, (anterior, actual) {
      if (actual.error != null && actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actual.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de Cupo de Crédito')),
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
                        child: Center(child: Text('No hay solicitudes de crédito pendientes.')),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.pendientes.length,
                    itemBuilder: (context, index) {
                      final pendiente = estado.pendientes[index];
                      final procesando = estado.procesando.contains(pendiente.clienteId);
                      return _TarjetaSolicitudCredito(
                        pendiente: pendiente,
                        plazos: plazos,
                        procesando: procesando,
                        onAutorizar: () => controller.autorizar(pendiente.clienteId),
                        onRechazar: () async {
                          final motivo = await showDialog<String>(
                            context: context,
                            builder: (_) => const RechazarCreditoDialog(),
                          );
                          if (motivo != null) await controller.rechazar(pendiente.clienteId, motivo);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaSolicitudCredito extends StatelessWidget {
  const _TarjetaSolicitudCredito({
    required this.pendiente,
    required this.plazos,
    required this.procesando,
    required this.onAutorizar,
    required this.onRechazar,
  });

  final SolicitudCreditoPendiente pendiente;
  final List<PlazoPago> plazos;
  final bool procesando;
  final VoidCallback onAutorizar;
  final VoidCallback onRechazar;

  String _nombrePlazo(String? plazoPagoId) {
    if (plazoPagoId == null) return 'Inmediato';
    for (final plazo in plazos) {
      if (plazo.id == plazoPagoId) return plazo.nombre;
    }
    return 'Plazo de pago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pendiente.clienteNombre} · ${pendiente.clienteRut}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (pendiente.tieneCupoVigente)
              Text(
                key: const Key('creditoPendienteCupoVigente'),
                'Ya tiene cupo vigente: ${MonedaFormatter.formatear(pendiente.cupoCreditoActual)} · ${_nombrePlazo(pendiente.plazoPagoIdActual)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
              )
            else
              const Text('Sin cupo vigente'),
            Text(
              'Cupo solicitado: ${MonedaFormatter.formatear(pendiente.cupoCreditoSolicitado)} · ${_nombrePlazo(pendiente.plazoPagoIdSolicitado)}',
            ),
            if (pendiente.observacion != null && pendiente.observacion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Observación: ${pendiente.observacion}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('creditoPendienteRechazar_${pendiente.clienteId}'),
                    onPressed: procesando ? null : onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('creditoPendienteAutorizar_${pendiente.clienteId}'),
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
