import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/movimiento_cuenta_cliente.dart';
import '../providers/receivables_providers.dart';
import '../widgets/registrar_abono_dialog.dart';

class DetalleCuentaClienteScreen extends ConsumerWidget {
  const DetalleCuentaClienteScreen({super.key, required this.clienteId});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(detalleCuentaProvider(clienteId));
    final controller = ref.read(detalleCuentaProvider(clienteId).notifier);
    final detalle = estado.detalle;

    return Scaffold(
      appBar: AppBar(title: Text(detalle?.nombreCliente ?? 'Cuenta por Cobrar')),
      floatingActionButton: detalle == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('registrarAbonoBoton'),
              onPressed: () => _registrarAbono(context, ref, detalle.saldoActual),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar abono'),
            ),
      body: estado.cargando && detalle == null
          ? const Center(child: CircularProgressIndicator())
          : detalle == null
              ? Center(child: Text(estado.error ?? 'No se pudo cargar la Cuenta.'))
              : RefreshIndicator(
                  onRefresh: controller.cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(detalle.rutCliente ?? 'Sin RUT', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text('Saldo actual', style: Theme.of(context).textTheme.labelLarge),
                      Text(
                        MonedaFormatter.formatear(detalle.saldoActual),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Movimientos', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      if (detalle.movimientos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Sin movimientos.')),
                        )
                      else
                        for (final movimiento in detalle.movimientos) _TarjetaMovimiento(movimiento: movimiento),
                    ],
                  ),
                ),
    );
  }

  Future<void> _registrarAbono(BuildContext context, WidgetRef ref, double saldoActual) async {
    final solicitado = await showDialog<AbonoSolicitado>(
      context: context,
      builder: (_) => RegistrarAbonoDialog(saldoActual: saldoActual),
    );
    if (solicitado == null) return;
    await ref.read(detalleCuentaProvider(clienteId).notifier).registrarAbono(
          monto: solicitado.monto,
          medioPago: solicitado.medioPago,
          motivo: solicitado.motivo,
        );
  }
}

class _TarjetaMovimiento extends StatelessWidget {
  const _TarjetaMovimiento({required this.movimiento});

  final MovimientoCuentaCliente movimiento;

  static final _formatoFecha = DateFormat('dd-MM-yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('movimiento_${movimiento.id}'),
      child: ListTile(
        leading: Icon(
          movimiento.esCargo ? Icons.arrow_upward : Icons.arrow_downward,
          color: movimiento.esCargo ? Theme.of(context).colorScheme.error : Colors.green,
        ),
        title: Text(movimiento.esCargo ? 'Cargo' : 'Abono'),
        subtitle: Text([
          if (movimiento.fechaVencimiento != null) 'Vence ${_formatoFecha.format(movimiento.fechaVencimiento!)}',
          if (movimiento.medioPago != null) movimiento.medioPago!.etiqueta,
          if (movimiento.motivo != null) movimiento.motivo!,
        ].join(' · ')),
        trailing: Text(
          MonedaFormatter.formatear(movimiento.monto),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: movimiento.esCargo ? Theme.of(context).colorScheme.error : Colors.green,
          ),
        ),
      ),
    );
  }
}
