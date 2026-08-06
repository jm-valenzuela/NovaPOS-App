import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/resolver_discrepancia_dialog.dart';

class DiscrepanciasScreen extends ConsumerWidget {
  const DiscrepanciasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(discrepanciasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discrepancias')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('discrepanciaFiltroPendientes'),
                  label: const Text('Pendientes'),
                  selected: estado.filtroEstado == EstadoDiscrepancia.pendiente,
                  onSelected: (_) => ref.read(discrepanciasProvider.notifier).cargar(filtroEstado: EstadoDiscrepancia.pendiente),
                ),
                ChoiceChip(
                  key: const Key('discrepanciaFiltroResueltas'),
                  label: const Text('Resueltas'),
                  selected: estado.filtroEstado == EstadoDiscrepancia.resuelta,
                  onSelected: (_) => ref.read(discrepanciasProvider.notifier).cargar(filtroEstado: EstadoDiscrepancia.resuelta),
                ),
                ChoiceChip(
                  key: const Key('discrepanciaFiltroTodas'),
                  label: const Text('Todas'),
                  selected: estado.filtroEstado == null,
                  onSelected: (_) => ref.read(discrepanciasProvider.notifier).cargar(limpiarFiltro: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: estado.cargando
                ? const Center(child: CircularProgressIndicator())
                : estado.discrepancias.isEmpty
                    ? const Center(child: Text('Sin discrepancias'))
                    : ListView.separated(
                        itemCount: estado.discrepancias.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final discrepancia = estado.discrepancias[index];
                          final diferenciaPositiva = discrepancia.diferencia > 0;
                          return ListTile(
                            key: Key('discrepancia_${discrepancia.id}'),
                            title: Text(
                              '${diferenciaPositiva ? "Cobró de más" : "Cobró de menos"}: ${MonedaFormatter.formatear(discrepancia.diferencia.abs())}',
                            ),
                            subtitle: Text(
                              'Documento ${MonedaFormatter.formatear(discrepancia.montoDocumento)} · '
                              'Negociado ${MonedaFormatter.formatear(discrepancia.montoNegociado)}'
                              '${discrepancia.motivoResolucion != null ? '\nResuelta: ${discrepancia.motivoResolucion}' : ''}',
                            ),
                            isThreeLine: discrepancia.motivoResolucion != null,
                            trailing: discrepancia.estado == EstadoDiscrepancia.pendiente
                                ? OutlinedButton(
                                    key: Key('resolverDiscrepancia_${discrepancia.id}'),
                                    onPressed: () => showDialog<bool>(
                                      context: context,
                                      builder: (_) => ResolverDiscrepanciaDialog(discrepanciaId: discrepancia.id),
                                    ),
                                    child: const Text('Resolver'),
                                  )
                                : const Icon(Icons.check_circle, color: Colors.green),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
