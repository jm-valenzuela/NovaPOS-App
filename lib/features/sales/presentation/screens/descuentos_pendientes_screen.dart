import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/descuento_pendiente.dart';
import '../providers/descuentos_pendientes_providers.dart';
import '../widgets/rechazar_descuento_dialog.dart';

/// Pantalla del Supervisor (permiso "sales.descuentos.autorizar") — la
/// misma cola de trabajo sirve tanto si está parado junto al Cajero como
/// si está en la oficina, no hay dos mecanismos distintos.
class DescuentosPendientesScreen extends ConsumerWidget {
  const DescuentosPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(descuentosPendientesProvider);
    final controller = ref.read(descuentosPendientesProvider.notifier);

    ref.listen(descuentosPendientesProvider, (anterior, actual) {
      if (actual.error != null && actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actual.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Descuentos pendientes')),
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
                        child: Center(child: Text('No hay descuentos pendientes de autorización.')),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.pendientes.length,
                    itemBuilder: (context, index) {
                      final pendiente = estado.pendientes[index];
                      final procesando = estado.procesando.contains(pendiente.ventaId);
                      return _TarjetaDescuentoPendiente(
                        pendiente: pendiente,
                        procesando: procesando,
                        onAutorizar: () => controller.autorizar(pendiente.ventaId),
                        onRechazar: () async {
                          final motivo = await showDialog<String>(
                            context: context,
                            builder: (_) => const RechazarDescuentoDialog(),
                          );
                          if (motivo != null) await controller.rechazar(pendiente.ventaId, motivo);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaDescuentoPendiente extends StatelessWidget {
  const _TarjetaDescuentoPendiente({
    required this.pendiente,
    required this.procesando,
    required this.onAutorizar,
    required this.onRechazar,
  });

  final DescuentoPendiente pendiente;
  final bool procesando;
  final VoidCallback onAutorizar;
  final VoidCallback onRechazar;

  String get _etiquetaDescuento => pendiente.porcentaje != null
      ? '${_formatearNumero(pendiente.porcentaje!)}% de descuento'
      : '${MonedaFormatter.formatear(pendiente.monto!)} de descuento';

  static String _formatearNumero(double n) => n.truncateToDouble() == n ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtotal: ${MonedaFormatter.formatear(pendiente.subtotalLineas)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_etiquetaDescuento),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('descuentoPendienteRechazar_${pendiente.ventaId}'),
                    onPressed: procesando ? null : onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('descuentoPendienteAutorizar_${pendiente.ventaId}'),
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
