import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/orden_compra.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/agregar_linea_orden_compra_dialog.dart';
import '../widgets/recibir_orden_compra_dialog.dart';

class OrdenCompraDetalleScreen extends ConsumerWidget {
  const OrdenCompraDetalleScreen({super.key, required this.ordenCompraId});

  final String ordenCompraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(ordenCompraDetalleProvider(ordenCompraId));
    final orden = estado.orden;

    return Scaffold(
      appBar: AppBar(title: const Text('Orden de Compra')),
      body: estado.cargando && orden == null
          ? const Center(child: CircularProgressIndicator())
          : orden == null
              ? Center(child: Text(estado.error ?? 'No se pudo cargar la Orden.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (estado.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(orden.estado.etiqueta)),
                          Text(MonedaFormatter.formatear(orden.total), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: orden.lineas.isEmpty
                            ? const Center(child: Text('Sin líneas'))
                            : ListView.separated(
                                itemCount: orden.lineas.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final linea = orden.lineas[index];
                                  return ListTile(
                                    key: Key('lineaOrdenCompra_${linea.varianteProductoId}'),
                                    title: Text(linea.nombreProducto),
                                    subtitle: Text(
                                      '${_formatearCantidad(linea.cantidad)} x ${MonedaFormatter.formatear(linea.costoUnitario)}'
                                      '${linea.cantidadRecibida > 0 ? ' · recibido ${_formatearCantidad(linea.cantidadRecibida)}' : ''}',
                                    ),
                                    trailing: Text(MonedaFormatter.formatear(linea.subtotal)),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (orden.estado == EstadoOrdenCompra.borrador) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('agregarLineaBoton'),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar línea'),
                                onPressed: () => _agregarLinea(context, ref),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('enviarOrdenBoton'),
                                icon: const Icon(Icons.send),
                                label: const Text('Enviar'),
                                onPressed: orden.lineas.isEmpty ? null : () => _enviar(context, ref),
                              ),
                            ),
                          ],
                          if (orden.estado == EstadoOrdenCompra.enviada || orden.estado == EstadoOrdenCompra.parcialmenteRecibida)
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('recibirOrdenBoton'),
                                icon: const Icon(Icons.inventory),
                                label: const Text('Recibir mercadería'),
                                onPressed: () => _recibir(context, ref, orden.lineas.where((l) => l.cantidadPendiente > 0).toList()),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  static String _formatearCantidad(double cantidad) =>
      cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();

  Future<void> _agregarLinea(BuildContext context, WidgetRef ref) async {
    await showDialog<bool>(context: context, builder: (_) => AgregarLineaOrdenCompraDialog(ordenCompraId: ordenCompraId));
  }

  Future<void> _enviar(BuildContext context, WidgetRef ref) async {
    await ref.read(ordenCompraDetalleProvider(ordenCompraId).notifier).enviar();
  }

  Future<void> _recibir(BuildContext context, WidgetRef ref, List<LineaOrdenCompra> lineasPendientes) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => RecibirOrdenCompraDialog(ordenCompraId: ordenCompraId, lineasPendientes: lineasPendientes),
    );
  }
}
