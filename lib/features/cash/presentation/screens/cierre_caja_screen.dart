import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formateador_miles.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../providers/cash_providers.dart';
import '../widgets/resumen_caja_widgets.dart';

/// Cierre de Caja — muestra cómo partió y cómo va la Sesión (o cómo quedó,
/// si ya está Cerrada), la lista de todos los movimientos, y pide el
/// conteo físico del efectivo antes de cerrar (ver ResumenCierreCaja en el
/// backend, mismo criterio que un Ajuste de Inventario).
class CierreCajaScreen extends ConsumerStatefulWidget {
  const CierreCajaScreen({super.key, required this.sesionCajaId});

  final String sesionCajaId;

  @override
  ConsumerState<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends ConsumerState<CierreCajaScreen> {
  final _montoContadoController = TextEditingController();

  @override
  void dispose() {
    _montoContadoController.dispose();
    super.dispose();
  }

  Future<void> _cerrar() async {
    final montoContado = FormateadorMiles.desformatear(_montoContadoController.text);
    if (_montoContadoController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa el monto contado en efectivo')));
      return;
    }
    final exito = await ref.read(resumenCierreProvider(widget.sesionCajaId).notifier).cerrar(montoContado);
    if (!mounted) return;
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caja cerrada.'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(resumenCierreProvider(widget.sesionCajaId));
    final resumen = estado.resumen;

    ref.listen(resumenCierreProvider(widget.sesionCajaId), (anterior, actual) {
      if (actual.error != null && actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actual.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de Caja')),
      body: estado.cargando && resumen == null
          ? const Center(child: CircularProgressIndicator())
          : resumen == null
              ? const Center(child: Text('No se pudo cargar el resumen.'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(resumenCierreProvider(widget.sesionCajaId).notifier).cargar(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      TarjetaResumenCaja(resumen: resumen),
                      const SizedBox(height: 16),
                      if (!resumen.cerrada) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Conteo físico', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextField(
                                  key: const Key('cierreCajaMontoContado'),
                                  controller: _montoContadoController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FormateadorMiles()],
                                  decoration: const InputDecoration(labelText: 'Monto contado en efectivo', prefixText: '\$ '),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                if (_montoContadoController.text.isNotEmpty)
                                  Builder(builder: (context) {
                                    final contado = double.tryParse(_montoContadoController.text.replaceAll(',', '.'));
                                    if (contado == null) return const SizedBox.shrink();
                                    final diferencia = contado - resumen.montoEsperado;
                                    return Text(
                                      'Diferencia: ${MonedaFormatter.formatear(diferencia)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: diferencia == 0
                                            ? Colors.green
                                            : Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    key: const Key('cierreCajaConfirmar'),
                                    onPressed: estado.cerrando ? null : _cerrar,
                                    child: estado.cerrando
                                        ? const SizedBox(
                                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Cerrar Caja'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (resumen.movimientos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('Sin movimientos en esta Sesión.')),
                        )
                      else
                        ...resumen.movimientos.map((m) => TarjetaMovimientoCaja(movimiento: m)),
                    ],
                  ),
                ),
    );
  }
}
