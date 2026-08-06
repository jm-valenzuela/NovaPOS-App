import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/cotizacion.dart';
import '../providers/pos_providers.dart';

/// Lista las Cotizaciones vigentes de la Sucursal de la Caja actual — al
/// tocar una, se cierra el diálogo devolviéndola (quien llama decide qué
/// hacer, ver PosScreen._rescatarCotizacion: pide confirmación si el
/// carrito actual no está vacío antes de reemplazarlo).
class RescatarCotizacionDialog extends ConsumerStatefulWidget {
  const RescatarCotizacionDialog({super.key, required this.sucursalId});

  final String sucursalId;

  @override
  ConsumerState<RescatarCotizacionDialog> createState() => _RescatarCotizacionDialogState();
}

class _RescatarCotizacionDialogState extends ConsumerState<RescatarCotizacionDialog> {
  late Future<List<CotizacionResumen>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(salesRepositoryProvider).listarCotizaciones(widget.sucursalId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rescatar Cotización'),
      content: SizedBox(
        width: 420,
        height: 400,
        child: FutureBuilder<List<CotizacionResumen>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('No se pudieron cargar las cotizaciones: ${snapshot.error}'));
            }
            final cotizaciones = snapshot.data!;
            if (cotizaciones.isEmpty) {
              return const Center(child: Text('No hay cotizaciones guardadas en esta Sucursal.'));
            }
            return ListView.separated(
              itemCount: cotizaciones.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cotizacion = cotizaciones[index];
                return ListTile(
                  key: Key('cotizacionRescatable_${cotizacion.ventaId}'),
                  title: Text(cotizacion.clienteNombre),
                  subtitle: Text(
                    '${DateFormat('dd-MM-yyyy HH:mm').format(cotizacion.fechaVenta.toLocal())} · '
                    '${cotizacion.cantidadLineas} ${cotizacion.cantidadLineas == 1 ? "producto" : "productos"}',
                  ),
                  trailing: Text(MonedaFormatter.formatear(cotizacion.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.of(context).pop(cotizacion),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
