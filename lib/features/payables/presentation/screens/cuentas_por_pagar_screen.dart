import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/proveedor_por_pagar.dart';
import '../providers/payables_providers.dart';

/// Listado global de Cuentas por Pagar — todos los Proveedores con saldo
/// pendiente, más atrasado primero (ya viene ordenado del backend, ver
/// ListarCuentasPorPagarQuery). "Al día" no aparece acá: solo se listan
/// Proveedores con SaldoTotal > 0.
class CuentasPorPagarScreen extends ConsumerWidget {
  const CuentasPorPagarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentasPorPagarProvider);
    final controller = ref.read(cuentasPorPagarProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas por Pagar')),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: estado.cargando && estado.proveedores.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.proveedores.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Sin Proveedores con saldo pendiente.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: estado.proveedores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final proveedor = estado.proveedores[index];
                      return _TarjetaProveedor(
                        proveedor: proveedor,
                        onTap: () => context.push('/compras/cuentas-por-pagar/${proveedor.proveedorId}'),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TarjetaProveedor extends StatelessWidget {
  const _TarjetaProveedor({required this.proveedor, required this.onTap});

  final ProveedorPorPagar proveedor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Layout manual en vez de ListTile: su trailing constriñe la altura a
    // la del tile (56 con título+subtítulo), insuficiente para monto +
    // badge apilados — acá el Row completo puede crecer lo que necesite.
    return Card(
      key: Key('cuentaPorPagarProveedor_${proveedor.proveedorId}'),
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
                    Text(proveedor.nombre, style: Theme.of(context).textTheme.titleMedium),
                    Text(proveedor.rut ?? 'Sin RUT', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(MonedaFormatter.formatear(proveedor.saldoTotal), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(proveedor.estaVencido ? 'Vencido (${proveedor.diasAtraso}d)' : 'Por vencer'),
                    backgroundColor: proveedor.estaVencido
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
