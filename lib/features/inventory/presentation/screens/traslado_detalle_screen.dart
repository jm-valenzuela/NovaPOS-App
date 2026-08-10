import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventory_enums.dart';
import '../../domain/models/traslado_inventario.dart';
import '../providers/inventory_providers.dart';
import '../widgets/agregar_linea_traslado_dialog.dart';
import '../widgets/recibir_traslado_dialog.dart';

class TrasladoDetalleScreen extends ConsumerWidget {
  const TrasladoDetalleScreen({super.key, required this.trasladoId});

  final String trasladoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(trasladoDetalleProvider(trasladoId));
    final traslado = estado.traslado;

    return Scaffold(
      appBar: AppBar(title: const Text('Traslado')),
      body: estado.cargando && traslado == null
          ? const Center(child: CircularProgressIndicator())
          : traslado == null
              ? Center(child: Text(estado.error ?? 'No se pudo cargar el Traslado.'))
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
                      Chip(label: Text(traslado.estado.etiqueta)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: traslado.lineas.isEmpty
                            ? const Center(child: Text('Sin líneas'))
                            : ListView.separated(
                                itemCount: traslado.lineas.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final linea = traslado.lineas[index];
                                  return ListTile(
                                    key: Key('lineaTraslado_${linea.varianteProductoId}'),
                                    title: Text(linea.nombreProducto),
                                    subtitle: Text(
                                      'Enviado: ${_formatearCantidad(linea.cantidadEnviada)}'
                                      '${linea.cantidadRecibida != null ? ' · Recibido: ${_formatearCantidad(linea.cantidadRecibida!)}' : ''}',
                                    ),
                                    trailing: (linea.diferencia != null && linea.diferencia != 0)
                                        ? Text(
                                            '${linea.diferencia! > 0 ? '+' : ''}${_formatearCantidad(linea.diferencia!)}',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                                          )
                                        : null,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (traslado.estado == EstadoTraslado.borrador) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('agregarLineaTrasladoBoton'),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar línea'),
                                onPressed: () => _agregarLinea(context, ref),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('enviarTrasladoBoton'),
                                icon: const Icon(Icons.send),
                                label: const Text('Enviar'),
                                onPressed: traslado.lineas.isEmpty ? null : () => _enviar(context, ref),
                              ),
                            ),
                          ],
                          if (traslado.estado == EstadoTraslado.enviado || traslado.estado == EstadoTraslado.parcialmenteRecibido)
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('recibirTrasladoBoton'),
                                icon: const Icon(Icons.inventory),
                                label: const Text('Recibir mercadería'),
                                onPressed: () => _recibir(
                                    context, ref, traslado.lineas.where((l) => l.cantidadPendiente > 0).toList()),
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
    await showDialog<bool>(context: context, builder: (_) => AgregarLineaTrasladoDialog(trasladoId: trasladoId));
  }

  Future<void> _enviar(BuildContext context, WidgetRef ref) async {
    await ref.read(trasladoDetalleProvider(trasladoId).notifier).enviar();
  }

  Future<void> _recibir(BuildContext context, WidgetRef ref, List<LineaTraslado> lineasPendientes) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => RecibirTrasladoDialog(trasladoId: trasladoId, lineasPendientes: lineasPendientes),
    );
  }
}
