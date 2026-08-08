import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/cliente_cobranza.dart';
import '../providers/receivables_providers.dart';

/// Listado global de Cobranzas — todos los Clientes con saldo pendiente,
/// más atrasado primero (ya viene ordenado del backend, ver
/// ListarCobranzaQuery). "Al día" no aparece acá: solo se listan Clientes
/// con SaldoTotal > 0.
class CobranzasScreen extends ConsumerWidget {
  const CobranzasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cobranzaProvider);
    final controller = ref.read(cobranzaProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Cobranzas')),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: estado.cargando && estado.clientes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.clientes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Sin Clientes con saldo pendiente.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.clientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cliente = estado.clientes[index];
                      return _TarjetaCliente(
                        cliente: cliente,
                        onTap: () => context.push('/clientes/cobranzas/${cliente.clienteId}'),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({required this.cliente, required this.onTap});

  final ClienteCobranza cliente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Layout manual en vez de ListTile: su trailing constriñe la altura a
    // la del tile (56 con título+subtítulo), insuficiente para monto +
    // badge apilados — acá el Row completo puede crecer lo que necesite.
    return Card(
      key: Key('cobranzaCliente_${cliente.clienteId}'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente.nombre, style: Theme.of(context).textTheme.titleMedium),
                    Text(cliente.rut ?? 'Sin RUT', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(MonedaFormatter.formatear(cliente.saldoTotal), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(cliente.estaVencido ? 'Vencido (${cliente.diasAtraso}d)' : 'Por vencer'),
                    backgroundColor: cliente.estaVencido
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
