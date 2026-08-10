import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventory_enums.dart';
import '../providers/inventory_providers.dart';
import '../widgets/registrar_conteo_dialog.dart';

class TomaInventarioDetalleScreen extends ConsumerWidget {
  const TomaInventarioDetalleScreen({super.key, required this.tomaId});

  final String tomaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(tomaInventarioDetalleProvider(tomaId));
    final toma = estado.toma;

    return Scaffold(
      appBar: AppBar(title: const Text('Toma de Inventario')),
      body: estado.cargando && toma == null
          ? const Center(child: CircularProgressIndicator())
          : toma == null
              ? Center(child: Text(estado.error ?? 'No se pudo cargar la Toma.'))
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
                      Chip(label: Text(toma.estado.etiqueta)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: toma.lineas.isEmpty
                            ? const Center(child: Text('Sin conteos registrados'))
                            : ListView.separated(
                                itemCount: toma.lineas.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final linea = toma.lineas[index];
                                  final difiere = linea.diferencia != 0;
                                  return ListTile(
                                    key: Key('lineaToma_${linea.varianteProductoId}'),
                                    title: Text(linea.nombreProducto),
                                    subtitle: Text(
                                      'Sistema: ${_formatearCantidad(linea.cantidadSistema)} · Contado: ${_formatearCantidad(linea.cantidadContada)}',
                                    ),
                                    trailing: Text(
                                      difiere ? '${linea.diferencia > 0 ? '+' : ''}${_formatearCantidad(linea.diferencia)}' : 'Sin diferencia',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: difiere ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (toma.estado == EstadoTomaInventario.abierta)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('registrarConteoBoton'),
                                icon: const Icon(Icons.add),
                                label: const Text('Registrar conteo'),
                                onPressed: () => _registrarConteo(context, ref),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('cerrarTomaBoton'),
                                icon: const Icon(Icons.check),
                                label: const Text('Cerrar Toma'),
                                onPressed: toma.lineas.isEmpty ? null : () => _cerrar(context, ref),
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

  Future<void> _registrarConteo(BuildContext context, WidgetRef ref) async {
    await showDialog<bool>(context: context, builder: (_) => RegistrarConteoDialog(tomaId: tomaId));
  }

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    await ref.read(tomaInventarioDetalleProvider(tomaId).notifier).cerrar();
  }
}
