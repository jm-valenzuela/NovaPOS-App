import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/promocion_grupo.dart';
import '../../domain/models/cotizacion.dart';
import '../../domain/models/resumen_venta.dart';
import '../providers/cotizaciones_providers.dart';
import '../providers/pos_providers.dart' show cajasProvider, salesRepositoryProvider;
import '../widgets/ticket_cotizacion.dart';

/// Sección para revisar las Cotizaciones guardadas — a diferencia de
/// "Rescatar cotización" en el POS (una lista corta pensada para elegir
/// rápido y seguir vendiendo), acá se ven todas las vigentes de la
/// Sucursal, se pueden buscar por número y reimprimir el ticket.
class CotizacionesScreen extends ConsumerStatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  ConsumerState<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends ConsumerState<CotizacionesScreen> {
  String? _sucursalId;
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<CotizacionResumen> _filtrar(List<CotizacionResumen> cotizaciones) {
    if (_busqueda.isEmpty) return cotizaciones;
    final texto = _busqueda.toLowerCase();
    return cotizaciones
        .where((c) =>
            (c.numeroCotizacion?.toLowerCase().contains(texto) ?? false) || c.clienteNombre.toLowerCase().contains(texto))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cajasAsync = ref.watch(cajasProvider);

    ref.listen(cajasProvider, (previo, actual) {
      actual.whenData((cajas) {
        if (_sucursalId == null && cajas.isNotEmpty) {
          final distintas = <String>{for (final c in cajas) c.sucursalId};
          if (distintas.length == 1) setState(() => _sucursalId = distintas.first);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones')),
      body: cajasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar la Sucursal: $error')),
        data: (cajas) {
          final sucursales = <String, String>{for (final c in cajas) c.sucursalId: c.nombreSucursal};
          if (sucursales.isEmpty) {
            return const Center(child: Text('Esta Empresa no tiene ninguna Sucursal configurada.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    if (sucursales.length > 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<String>(
                          key: const Key('cotizacionesSelectorSucursal'),
                          value: _sucursalId,
                          hint: const Text('Elige una Sucursal'),
                          items: sucursales.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (sucursalId) => setState(() => _sucursalId = sucursalId),
                        ),
                      ),
                    TextField(
                      key: const Key('cotizacionesBuscar'),
                      controller: _busquedaController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por número o Cliente',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (texto) => setState(() => _busqueda = texto.trim()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _sucursalId == null
                    ? const Center(child: Text('Elige con qué Sucursal vas a trabajar.'))
                    : _ListadoCotizaciones(sucursalId: _sucursalId!, filtrar: _filtrar),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListadoCotizaciones extends ConsumerWidget {
  const _ListadoCotizaciones({required this.sucursalId, required this.filtrar});

  final String sucursalId;
  final List<CotizacionResumen> Function(List<CotizacionResumen>) filtrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cotizacionesProvider(sucursalId));
    final controller = ref.read(cotizacionesProvider(sucursalId).notifier);

    ref.listen(cotizacionesProvider(sucursalId), (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actual.error!)));
      }
    });

    if (estado.cargando && estado.cotizaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.cotizaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay Cotizaciones guardadas en esta Sucursal.')),
            ),
          ],
        ),
      );
    }

    final filtradas = filtrar(estado.cotizaciones);
    return RefreshIndicator(
      onRefresh: controller.cargar,
      child: filtradas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Ninguna Cotización coincide con la búsqueda.')),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtradas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final cotizacion = filtradas[index];
                return Card(
                  child: ListTile(
                    key: Key('cotizacionItem_${cotizacion.ventaId}'),
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
                    onTap: () => showDialog(context: context, builder: (_) => _DetalleCotizacionDialog(ventaId: cotizacion.ventaId)),
                  ),
                );
              },
            ),
    );
  }
}

class _DetalleCotizacionDialog extends ConsumerStatefulWidget {
  const _DetalleCotizacionDialog({required this.ventaId});

  final String ventaId;

  @override
  ConsumerState<_DetalleCotizacionDialog> createState() => _DetalleCotizacionDialogState();
}

class _DetalleCotizacionDialogState extends ConsumerState<_DetalleCotizacionDialog> {
  late Future<CotizacionDetalle> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(salesRepositoryProvider).obtenerCotizacion(widget.ventaId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: const Text('Detalle de Cotización', style: TextStyle(fontWeight: FontWeight.w700)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<CotizacionDetalle>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(height: 100, child: Center(child: Text('No se pudo cargar: ${snapshot.error}')));
            }
            final detalle = snapshot.data!;
            final resumen = ResumenVenta.calcular(detalle.total);
            // subtotalLineas siempre es el total sin descuento y total ya lo
            // tiene restado (RecalcularTotal en el backend) — la diferencia
            // es el monto exacto del descuento general aplicado, mismo
            // cálculo que imprimirTicketCotizacion. 0 si nunca se autorizó.
            final montoDescuentoAplicado = detalle.subtotalLineas - detalle.total;
            final etiquetaDescuento = detalle.descuentoGeneralPorcentaje != null
                ? 'Descuento (${_formatearCantidad(detalle.descuentoGeneralPorcentaje!)}%)'
                : 'Descuento';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detalle.numeroCotizacion != null) ...[
                  Text(
                    detalle.numeroCotizacion!,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cliente: ${detalle.clienteNombre}${detalle.clienteRut != null ? ' · ${detalle.clienteRut}' : ''}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    itemCount: detalle.lineas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final linea = detalle.lineas[index];
                      final tieneOferta =
                          linea.precioOferta != null && linea.precioOferta == linea.precioUnitario && linea.precioVenta != null;
                      final etiqueta = linea.porcentajeDescuentoAplicado != null
                          ? '${_formatearCantidad(linea.porcentajeDescuentoAplicado!)}% dto. por volumen aplicado'
                          : linea.montoDescuentoPromocion != null
                              ? _etiquetaPromocionLinea(linea)
                              : (tieneOferta ? 'Oferta aplicada' : null);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(linea.nombreProducto)),
                              const SizedBox(width: 12),
                              Text(MonedaFormatter.formatear(linea.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (tieneOferta) ...[
                                Text(
                                  MonedaFormatter.formatear(linea.precioVenta!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '${_formatearCantidad(linea.cantidad)} x ${MonedaFormatter.formatear(linea.precioUnitario)}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (etiqueta != null) ...[
                            const SizedBox(height: 2),
                            Text(etiqueta, style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                if (montoDescuentoAplicado > 0) ...[
                  _FilaResumen(
                    etiqueta: etiquetaDescuento,
                    valor: '-${MonedaFormatter.formatear(montoDescuentoAplicado)}',
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 4),
                ],
                _FilaResumen(etiqueta: 'Subtotal', valor: MonedaFormatter.formatear(resumen.neto)),
                const SizedBox(height: 4),
                _FilaResumen(etiqueta: 'IVA (19%)', valor: MonedaFormatter.formatear(resumen.iva)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      MonedaFormatter.formatear(detalle.total),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        FilledButton.icon(
          key: const Key('cotizacionDetalleImprimir'),
          icon: const Icon(Icons.print),
          label: const Text('Imprimir'),
          onPressed: () async {
            final detalle = await _futuro;
            await imprimirTicketCotizacion(detalle);
          },
        ),
      ],
    );
  }
}

/// Fila etiqueta/valor del desglose (Descuento/Subtotal/IVA) — mismo criterio
/// visual que _filaResumen en ticket_cotizacion.dart, versión Flutter widget.
class _FilaResumen extends StatelessWidget {
  const _FilaResumen({required this.etiqueta, required this.valor, this.color});

  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(color: color ?? Theme.of(context).colorScheme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(etiqueta, style: estilo), Text(valor, style: estilo)],
    );
  }
}

String _formatearCantidad(double cantidad) => cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();

/// Mismo criterio que _etiquetaPromocion en ticket_cotizacion.dart — si el
/// preset (2x1, 4x3, etc.) sigue disponible, muestra la misma etiqueta que
/// se ve en el carrito, en vez del texto genérico.
String _etiquetaPromocionLinea(LineaCotizacionDetalle linea) {
  final cantidadPorGrupo = linea.cantidadPorGrupoPromocion;
  final porcentaje = linea.porcentajeDescuentoUnidadPromocion;
  if (cantidadPorGrupo != null && porcentaje != null) {
    return '${PromocionGrupo.etiqueta(cantidadPorGrupo, porcentaje)} aplicado';
  }
  return 'Promoción aplicada (-${MonedaFormatter.formatear(linea.montoDescuentoPromocion!)})';
}
