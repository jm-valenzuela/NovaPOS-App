import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../customers/domain/models/plazo_pago.dart';
import '../../../customers/presentation/providers/customer_admin_providers.dart';
import '../../domain/models/cliente_cobranza.dart';
import '../providers/receivables_providers.dart';

/// Listado global de Cobranzas — TODOS los Clientes con Cupo de Crédito
/// asignado (tengan o no saldo pendiente ahora mismo), más atrasado
/// primero (ya viene ordenado del backend, ver ListarCobranzaQuery).
class CobranzasScreen extends ConsumerWidget {
  const CobranzasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cobranzaProvider);
    final controller = ref.read(cobranzaProvider.notifier);
    // Mismo catálogo que usa ClienteFormDialog para resolver el nombre del
    // Plazo de Pago — se carga una sola vez acá y se resuelve por Id.
    final plazos = ref.watch(plazosPagoProvider).plazos;

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
                        child: Center(child: Text('Sin Clientes con Cupo de Crédito asignado.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.clientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cliente = estado.clientes[index];
                      PlazoPago? plazo;
                      for (final p in plazos) {
                        if (p.id == cliente.plazoPagoId) {
                          plazo = p;
                          break;
                        }
                      }
                      return _TarjetaCliente(
                        cliente: cliente,
                        nombrePlazo: plazo?.nombre,
                        onTap: () => context.push('/clientes/cobranzas/${cliente.clienteId}'),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({required this.cliente, required this.nombrePlazo, required this.onTap});

  final ClienteCobranza cliente;
  final String? nombrePlazo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('cobranzaCliente_${cliente.clienteId}'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Text(
                        MonedaFormatter.formatear(cliente.saldoTotal),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          cliente.sinDeudaVigente
                              ? 'Al día'
                              : cliente.estaVencido
                                  ? 'Vencido (${cliente.diasAtraso}d)'
                                  : 'Por vencer',
                        ),
                        backgroundColor: cliente.sinDeudaVigente
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : cliente.estaVencido
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.secondaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(child: _DatoCredito(etiqueta: 'Cupo', valor: MonedaFormatter.formatear(cliente.cupoCredito))),
                  Expanded(
                    child: _DatoCredito(etiqueta: 'Utilizado', valor: MonedaFormatter.formatear(cliente.saldoTotal)),
                  ),
                  Expanded(
                    child:
                        _DatoCredito(etiqueta: 'Por vencer', valor: MonedaFormatter.formatear(cliente.saldoPorVencer)),
                  ),
                  Expanded(child: _DatoCredito(etiqueta: 'Plazo de pago', valor: nombrePlazo ?? 'Sin asignar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoCredito extends StatelessWidget {
  const _DatoCredito({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
        Text(valor, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
