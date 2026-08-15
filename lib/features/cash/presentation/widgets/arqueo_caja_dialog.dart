import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cash_providers.dart';
import 'resumen_caja_widgets.dart';

/// Consulta rápida de "qué debería haber en la Caja ahora mismo" — a
/// pedido explícito del usuario: "falta una opción donde puedas ver el
/// estatus de la caja, como un arqueo visual, cuando en algún momento
/// necesitas ver qué es lo que tiene la caja para cuadrarte, es muy
/// práctico". A diferencia de CierreCajaScreen (que además pide el conteo
/// físico y cierra la Sesión), este diálogo es de solo lectura — mismo
/// GET /caja/sesiones/{id}/resumen-cierre (preview en vivo mientras la
/// Sesión sigue Abierta), sin ninguna acción de cierre.
class ArqueoCajaDialog extends ConsumerWidget {
  const ArqueoCajaDialog({super.key, required this.sesionCajaId});

  final String sesionCajaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(resumenCierreProvider(sesionCajaId));
    final resumen = estado.resumen;

    return AlertDialog(
      title: const Text('Arqueo de Caja'),
      content: SizedBox(
        width: 420,
        height: 480,
        child: estado.cargando && resumen == null
            ? const Center(child: CircularProgressIndicator())
            : resumen == null
                ? Center(child: Text(estado.error ?? 'No se pudo cargar el resumen.'))
                : RefreshIndicator(
                    onRefresh: () => ref.read(resumenCierreProvider(sesionCajaId).notifier).cargar(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        TarjetaResumenCaja(resumen: resumen),
                        const SizedBox(height: 16),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
