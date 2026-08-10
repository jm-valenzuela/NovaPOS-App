import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/flujo_caja_dia.dart';
import '../providers/reporting_providers.dart';

/// Grilla de Ingresos/Egresos por día en un período elegible — Real
/// (efectivo que realmente entró/salió de caja) y Proyectado (según
/// FechaVencimiento de los Cargos pendientes), ver FlujoCajaQuery en el
/// backend. Fila de totales al final, columnas de Neto en verde/rojo
/// según el signo.
class FlujoCajaScreen extends ConsumerWidget {
  const FlujoCajaScreen({super.key});

  static final _formatoFecha = DateFormat('dd-MM-yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(flujoCajaProvider);
    final controller = ref.read(flujoCajaProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flujo de Caja'),
        actions: [
          IconButton(
            key: const Key('flujoCajaElegirPeriodo'),
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Elegir período',
            onPressed: () => _elegirPeriodo(context, estado, controller),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${_formatoFecha.format(estado.desde)} — ${_formatoFecha.format(estado.hasta)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: estado.cargando
                ? const Center(child: CircularProgressIndicator())
                : estado.dias.isEmpty
                    ? const Center(child: Text('Sin movimientos en el período elegido.'))
                    : RefreshIndicator(
                        onRefresh: controller.cargar,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _GrillaFlujoCaja(dias: estado.dias),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirPeriodo(BuildContext context, FlujoCajaState estado, FlujoCajaController controller) async {
    final elegido = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: estado.desde, end: estado.hasta),
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
    );
    if (elegido == null) return;
    await controller.cambiarPeriodo(desde: elegido.start, hasta: elegido.end);
  }
}

class _GrillaFlujoCaja extends StatelessWidget {
  const _GrillaFlujoCaja({required this.dias});

  final List<FlujoCajaDia> dias;

  static final _formatoFecha = DateFormat('dd-MM-yyyy');

  @override
  Widget build(BuildContext context) {
    final totalEntradaReal = dias.fold(0.0, (acc, d) => acc + d.entradaReal);
    final totalSalidaReal = dias.fold(0.0, (acc, d) => acc + d.salidaReal);
    final totalNetoReal = dias.fold(0.0, (acc, d) => acc + d.flujoNetoReal);
    final totalEntradaProyectada = dias.fold(0.0, (acc, d) => acc + d.entradaProyectada);
    final totalSalidaProyectada = dias.fold(0.0, (acc, d) => acc + d.salidaProyectada);
    final totalNetoProyectado = dias.fold(0.0, (acc, d) => acc + d.flujoNetoProyectado);

    return DataTable(
      key: const Key('grillaFlujoCaja'),
      columns: const [
        DataColumn(label: Text('Fecha')),
        DataColumn(label: Text('Ingresos (Real)'), numeric: true),
        DataColumn(label: Text('Egresos (Real)'), numeric: true),
        DataColumn(label: Text('Neto (Real)'), numeric: true),
        DataColumn(label: Text('Ingresos (Proyectado)'), numeric: true),
        DataColumn(label: Text('Egresos (Proyectado)'), numeric: true),
        DataColumn(label: Text('Neto (Proyectado)'), numeric: true),
      ],
      rows: [
        for (final dia in dias)
          DataRow(
            key: ValueKey('filaFlujoCaja_${dia.fecha.toIso8601String()}'),
            cells: [
              DataCell(Text(_formatoFecha.format(dia.fecha))),
              DataCell(Text(MonedaFormatter.formatear(dia.entradaReal))),
              DataCell(Text(MonedaFormatter.formatear(dia.salidaReal))),
              DataCell(_CeldaNeto(monto: dia.flujoNetoReal)),
              DataCell(Text(MonedaFormatter.formatear(dia.entradaProyectada))),
              DataCell(Text(MonedaFormatter.formatear(dia.salidaProyectada))),
              DataCell(_CeldaNeto(monto: dia.flujoNetoProyectado)),
            ],
          ),
        DataRow(
          key: const ValueKey('filaFlujoCajaTotales'),
          color: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
          cells: [
            const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(MonedaFormatter.formatear(totalEntradaReal), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(MonedaFormatter.formatear(totalSalidaReal), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_CeldaNeto(monto: totalNetoReal, negrita: true)),
            DataCell(Text(MonedaFormatter.formatear(totalEntradaProyectada), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(MonedaFormatter.formatear(totalSalidaProyectada), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_CeldaNeto(monto: totalNetoProyectado, negrita: true)),
          ],
        ),
      ],
    );
  }
}

class _CeldaNeto extends StatelessWidget {
  const _CeldaNeto({required this.monto, this.negrita = false});

  final double monto;
  final bool negrita;

  @override
  Widget build(BuildContext context) {
    final color = monto < 0 ? Theme.of(context).colorScheme.error : Colors.green;
    return Text(
      MonedaFormatter.formatear(monto),
      style: TextStyle(color: color, fontWeight: negrita ? FontWeight.bold : FontWeight.normal),
    );
  }
}
