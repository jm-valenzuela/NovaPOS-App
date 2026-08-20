import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../providers/workorders_providers.dart';

/// Historial de Órdenes de Trabajo de un Cliente — a pedido explícito del
/// usuario: "si más adelante te solicita nuevamente el trabajo, tienes el
/// historial que puedas duplicar al momento de generar otra orden de
/// trabajo". Cada fila puede Duplicarse, lo que crea una Orden nueva con
/// la misma estructura de Ítems (ver DuplicarOrdenTrabajoCommand) — los
/// productos se re-cotizan al precio vigente, el trabajo copia el monto
/// anterior como punto de partida editable.
class HistorialClienteScreen extends ConsumerStatefulWidget {
  const HistorialClienteScreen({super.key, required this.clienteId, required this.clienteNombre});

  final String clienteId;
  final String clienteNombre;

  @override
  ConsumerState<HistorialClienteScreen> createState() => _HistorialClienteScreenState();
}

class _HistorialClienteScreenState extends ConsumerState<HistorialClienteScreen> {
  final Set<String> _duplicando = {};

  Future<void> _duplicar(String ordenTrabajoId) async {
    setState(() => _duplicando.add(ordenTrabajoId));
    final nuevaId = await ref.read(historialClienteProvider(widget.clienteId).notifier).duplicar(ordenTrabajoId);
    if (!mounted) return;
    setState(() => _duplicando.remove(ordenTrabajoId));
    if (nuevaId != null) context.push('/ordenes-trabajo/$nuevaId');
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(historialClienteProvider(widget.clienteId));

    return Scaffold(
      appBar: AppBar(title: Text('Historial · ${widget.clienteNombre}')),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.ordenes.isEmpty
              ? const Center(child: Text('Este Cliente no tiene Órdenes de Trabajo anteriores'))
              : ListView.separated(
                  itemCount: estado.ordenes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final orden = estado.ordenes[index];
                    final duplicando = _duplicando.contains(orden.id);
                    return ListTile(
                      key: Key('historialOrden_${orden.id}'),
                      title: Text('${orden.numero} · ${orden.descripcion}'),
                      subtitle: Text('${orden.estado.etiqueta} · ${orden.fechaRecepcion.toLocal().toString().split(' ').first}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (orden.montoAprobado != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(MonedaFormatter.formatear(orden.montoAprobado!)),
                            ),
                          duplicando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : OutlinedButton(
                                  key: Key('historialDuplicar_${orden.id}'),
                                  onPressed: () => _duplicar(orden.id),
                                  child: const Text('Duplicar'),
                                ),
                        ],
                      ),
                      onTap: () => context.push('/ordenes-trabajo/${orden.id}'),
                    );
                  },
                ),
    );
  }
}
