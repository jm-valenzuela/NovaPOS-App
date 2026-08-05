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

class _TarjetaDescuentoPendiente extends StatefulWidget {
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

  @override
  State<_TarjetaDescuentoPendiente> createState() => _TarjetaDescuentoPendienteState();
}

class _TarjetaDescuentoPendienteState extends State<_TarjetaDescuentoPendiente> {
  bool _expandido = false;

  String get _etiquetaDescuento => widget.pendiente.porcentaje != null
      ? '${_formatearNumero(widget.pendiente.porcentaje!)}% de descuento'
      : '${MonedaFormatter.formatear(widget.pendiente.monto!)} de descuento';

  static String _formatearNumero(double n) => n.truncateToDouble() == n ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    final pendiente = widget.pendiente;
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('descuentoPendienteVerMas_${pendiente.ventaId}'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => setState(() => _expandido = !_expandido),
                child: Text(_expandido ? 'Ver menos' : 'Ver más — Cliente y Productos'),
              ),
            ),
            if (_expandido) _DetalleDescuentoPendiente(ventaId: pendiente.ventaId),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('descuentoPendienteRechazar_${pendiente.ventaId}'),
                    onPressed: widget.procesando ? null : widget.onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('descuentoPendienteAutorizar_${pendiente.ventaId}'),
                    onPressed: widget.procesando ? null : widget.onAutorizar,
                    child: widget.procesando
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

/// Contenido de "Ver más" — se pide recién al expandir (provider .family),
/// no de entrada para toda la cola de pendientes.
class _DetalleDescuentoPendiente extends ConsumerWidget {
  const _DetalleDescuentoPendiente({required this.ventaId});

  final String ventaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(detalleDescuentoPendienteProvider(ventaId));

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: detalleAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        error: (error, _) => Text(
          'No se pudo cargar el detalle: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
        ),
        data: (detalle) => Container(
          key: Key('descuentoPendienteDetalle_$ventaId'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente', style: Theme.of(context).textTheme.labelSmall),
              Text(
                detalle.clienteRut == null ? detalle.clienteNombre : '${detalle.clienteNombre} · ${detalle.clienteRut}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text('Productos', style: Theme.of(context).textTheme.labelSmall),
              for (final linea in detalle.lineas)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatearCantidad(linea.cantidad)} × ${linea.nombreProducto}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(MonedaFormatter.formatear(linea.subtotal)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatearCantidad(double n) => n.truncateToDouble() == n ? n.toInt().toString() : n.toString();
}
