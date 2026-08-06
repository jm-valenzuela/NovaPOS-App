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
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(salesRepositoryProvider).listarCotizaciones(widget.sucursalId);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  static const _maximoResultados = 10;

  /// Filtra localmente por NumeroCotizacion — la lista ya viene completa
  /// del servidor (solo las vigentes de la Sucursal, un volumen acotado),
  /// así que no hace falta un endpoint de búsqueda aparte. Una Cotización
  /// sin número (guardada antes de que existiera este campo) no aparece
  /// mientras haya texto de búsqueda, ya que no tiene con qué compararla.
  /// El resultado, con o sin filtro, se acota a las últimas 10 (la lista
  /// ya viene ordenada por fecha descendente desde el backend — ver
  /// VentaRepository.ListarCotizacionesAsync) para que el listado no
  /// crezca sin límite a medida que se acumulan Cotizaciones vigentes.
  List<CotizacionResumen> _filtrar(List<CotizacionResumen> cotizaciones) {
    final resultado = _busqueda.isEmpty
        ? cotizaciones
        : cotizaciones.where((c) => c.numeroCotizacion?.toLowerCase().contains(_busqueda.toLowerCase()) ?? false);
    return resultado.take(_maximoResultados).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rescatar Cotización'),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            TextField(
              key: const Key('cotizacionBuscarNumero'),
              controller: _busquedaController,
              decoration: const InputDecoration(
                labelText: 'Buscar por número',
                hintText: 'COT-20260806-001',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (texto) => setState(() => _busqueda = texto.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
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
                  final filtradas = _filtrar(cotizaciones);
                  if (filtradas.isEmpty) {
                    return const Center(child: Text('Ninguna cotización coincide con la búsqueda.'));
                  }
                  return ListView.separated(
                    itemCount: filtradas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cotizacion = filtradas[index];
                      return ListTile(
                        key: Key('cotizacionRescatable_${cotizacion.ventaId}'),
                        title: Text(
                          cotizacion.numeroCotizacion != null
                              ? '${cotizacion.numeroCotizacion} · ${cotizacion.clienteNombre}'
                              : cotizacion.clienteNombre,
                        ),
                        subtitle: Text(
                          '${DateFormat('dd-MM-yyyy HH:mm').format(cotizacion.fechaVenta.toLocal())} · '
                          '${cotizacion.cantidadLineas} ${cotizacion.cantidadLineas == 1 ? "producto" : "productos"}',
                        ),
                        trailing:
                            Text(MonedaFormatter.formatear(cotizacion.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.of(context).pop(cotizacion),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
