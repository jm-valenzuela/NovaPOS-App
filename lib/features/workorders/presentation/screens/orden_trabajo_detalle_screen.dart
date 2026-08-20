import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show tenancyRepositoryProvider;
import '../../../sales/presentation/widgets/representacion_impresa_venta.dart';
import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';
import '../widgets/asignar_operador_dialog.dart';
import '../widgets/cobrar_orden_trabajo_dialog.dart';
import '../widgets/editar_observacion_dialog.dart';
import '../widgets/editor_item_orden_trabajo_dialog.dart';
import '../widgets/rechazar_item_dialog.dart';

/// Un imprevisto detectado durante la ejecución (ej. se encuentra que la
/// suspensión también está dañada) se agrega como un Ítem nuevo en
/// cualquier momento (salvo Orden ya Entregada) — no bloquea ni reabre los
/// Ítems que ya están aprobados o en curso, cada uno sigue su propio ciclo
/// (ver OrdenTrabajo en el backend).
class OrdenTrabajoDetalleScreen extends ConsumerWidget {
  const OrdenTrabajoDetalleScreen({super.key, required this.ordenTrabajoId});

  final String ordenTrabajoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(ordenTrabajoDetalleProvider(ordenTrabajoId));
    final orden = estado.orden;

    return Scaffold(
      appBar: AppBar(title: Text(orden?.numero ?? 'Orden de Trabajo')),
      floatingActionButton: (orden == null || orden.estado == EstadoOrdenTrabajo.entregada)
          ? null
          : FloatingActionButton.extended(
              key: const Key('agregarItemBoton'),
              onPressed: () => _agregarItem(context, orden.id),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Ítem'),
            ),
      body: estado.cargando && orden == null
          ? const Center(child: CircularProgressIndicator())
          : orden == null
              ? Center(child: Text(estado.error ?? 'No se pudo cargar la Orden.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (estado.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(orden.estado.etiqueta)),
                          if (orden.montoAprobado != null)
                            Text(MonedaFormatter.formatear(orden.montoAprobado!), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(orden.clienteNombre, style: Theme.of(context).textTheme.titleMedium),
                      if (orden.clienteRut != null) Text(orden.clienteRut!),
                      const SizedBox(height: 12),
                      Text(orden.descripcion),
                      const SizedBox(height: 8),
                      Text(
                        'Recibida: ${_formatearFecha(orden.fechaRecepcion)}'
                        '${orden.fechaEntrega != null ? ' · Entregada: ${_formatearFecha(orden.fechaEntrega!)}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (orden.items.isEmpty)
                        const Text('Sin Ítems todavía — agrega el primero con el botón de abajo.')
                      else ...[
                        Text('Ítems', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        for (final item in orden.items) _tarjetaItem(context, ref, orden.id, item),
                      ],
                      const SizedBox(height: 20),
                      if (orden.ventaId != null) ...[
                        Text('Venta vinculada', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        _ventaVinculada(context, ref, orden.ventaId!),
                        const SizedBox(height: 20),
                      ],
                      if (orden.estado == EstadoOrdenTrabajo.lista)
                        orden.montoAprobado == null
                            ? const Text('Todos los Ítems fueron rechazados — no hay nada que cobrar.')
                            : FilledButton.icon(
                                key: const Key('cobrarOtBoton'),
                                icon: const Icon(Icons.point_of_sale),
                                label: const Text('Cobrar'),
                                onPressed: () => _cobrar(context, ref, orden),
                              ),
                    ],
                  ),
                ),
    );
  }

  String _formatearFecha(DateTime fecha) => fecha.toLocal().toString().split(' ').first;

  Widget _ventaVinculada(BuildContext context, WidgetRef ref, String ventaId) {
    final estado = ref.watch(ventaVinculadaProvider(ventaId));
    return estado.when(
      loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => Text(ventaId, style: Theme.of(context).textTheme.bodySmall),
      data: (venta) => Row(
        children: [
          Expanded(
            child: Text(
              venta.tieneDte ? '${venta.etiquetaDocumento} N° ${venta.folio}' : 'Sin documento tributario emitido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (venta.tieneDte)
            TextButton.icon(
              key: const Key('imprimirVentaVinculadaBoton'),
              onPressed: () => imprimirBoletaFactura(venta.resumen, venta.lineasImpresion),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Imprimir'),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaItem(BuildContext context, WidgetRef ref, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) {
    return Card(
      key: Key('item_${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.descripcion, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _chipEstadoItem(item.estado),
              ],
            ),
            const SizedBox(height: 4),
            if (item.montoTotal != null)
              Text(MonedaFormatter.formatear(item.montoTotal!), style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final linea in item.lineas)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(linea.tipo == TipoLineaOrdenTrabajo.trabajo ? Icons.build_outlined : Icons.inventory_2_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        linea.tipo == TipoLineaOrdenTrabajo.producto ? '${linea.descripcion} x${linea.cantidad?.toStringAsFixed(0)}' : linea.descripcion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(MonedaFormatter.formatear(linea.monto), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            if (item.motivoRechazo != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Motivo: ${item.motivoRechazo}', style: Theme.of(context).textTheme.bodySmall),
              ),
            if (!item.cerrado) ...[
              const SizedBox(height: 6),
              InkWell(
                key: Key('itemObservacion_${item.id}'),
                onTap: () => _editarObservacion(context, ordenTrabajoId, item),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.observacion ?? 'Agregar observación',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                key: Key('itemOperador_${item.id}'),
                onTap: () => _asignarOperador(context, ordenTrabajoId, item),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 4),
                    Text(item.asignadoANombre ?? 'Asignar Operador', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            _accionesItem(context, ref, ordenTrabajoId, item),
            if (item.historial.isNotEmpty) _historialItem(context, item),
          ],
        ),
      ),
    );
  }

  Widget _historialItem(BuildContext context, ItemOrdenTrabajoDetalle item) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('itemHistorial_${item.id}'),
        tilePadding: EdgeInsets.zero,
        title: Text('Historial (${item.historial.length})', style: Theme.of(context).textTheme.bodySmall),
        children: [
          for (final evento in item.historial)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconoEvento(evento.tipo), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${evento.tipo.etiqueta}'
                          '${evento.usuarioNombre != null ? ' — ${evento.usuarioNombre}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(_formatearFecha(evento.fecha), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        if (evento.detalle != null)
                          Text(evento.detalle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconoEvento(TipoEventoItemOrdenTrabajo tipo) => switch (tipo) {
        TipoEventoItemOrdenTrabajo.creado => Icons.add_circle_outline,
        TipoEventoItemOrdenTrabajo.cotizado => Icons.request_quote_outlined,
        TipoEventoItemOrdenTrabajo.aprobado => Icons.check_circle_outline,
        TipoEventoItemOrdenTrabajo.rechazado => Icons.cancel_outlined,
        TipoEventoItemOrdenTrabajo.trabajoIniciado => Icons.play_circle_outline,
        TipoEventoItemOrdenTrabajo.terminado => Icons.done_all,
        TipoEventoItemOrdenTrabajo.observacionEditada => Icons.edit_note,
        TipoEventoItemOrdenTrabajo.operadorAsignado => Icons.person_outline,
      };

  Widget _chipEstadoItem(EstadoItemOrdenTrabajo estado) {
    final (color, icono) = switch (estado) {
      EstadoItemOrdenTrabajo.pendienteEvaluacion => (Colors.orange, Icons.search),
      EstadoItemOrdenTrabajo.cotizado => (Colors.blue, Icons.request_quote_outlined),
      EstadoItemOrdenTrabajo.aprobado => (Colors.teal, Icons.check_circle_outline),
      EstadoItemOrdenTrabajo.rechazado => (Colors.red, Icons.cancel_outlined),
      EstadoItemOrdenTrabajo.enTrabajo => (Colors.purple, Icons.play_circle_outline),
      EstadoItemOrdenTrabajo.terminado => (Colors.green, Icons.done_all),
    };
    return Chip(
      avatar: Icon(icono, size: 16, color: color),
      label: Text(estado.etiqueta),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _accionesItem(BuildContext context, WidgetRef ref, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) {
    switch (item.estado) {
      case EstadoItemOrdenTrabajo.pendienteEvaluacion:
        return FilledButton(
          key: Key('itemCotizarBoton_${item.id}'),
          onPressed: () => _cotizarItem(context, ordenTrabajoId, item),
          child: const Text('Cotizar'),
        );
      case EstadoItemOrdenTrabajo.cotizado:
        return Wrap(
          spacing: 8,
          children: [
            FilledButton(
              key: Key('itemAprobarBoton_${item.id}'),
              onPressed: () => ref.read(ordenTrabajoDetalleProvider(ordenTrabajoId).notifier).aprobarItem(item.id),
              child: const Text('Aprobar'),
            ),
            OutlinedButton(
              key: Key('itemRechazarBoton_${item.id}'),
              onPressed: () => _rechazarItem(context, ordenTrabajoId, item),
              child: const Text('Rechazar'),
            ),
          ],
        );
      case EstadoItemOrdenTrabajo.aprobado:
        return FilledButton(
          key: Key('itemIniciarTrabajoBoton_${item.id}'),
          onPressed: () => ref.read(ordenTrabajoDetalleProvider(ordenTrabajoId).notifier).iniciarTrabajoItem(item.id),
          child: const Text('Iniciar Trabajo'),
        );
      case EstadoItemOrdenTrabajo.enTrabajo:
        return FilledButton(
          key: Key('itemTerminarBoton_${item.id}'),
          onPressed: () => ref.read(ordenTrabajoDetalleProvider(ordenTrabajoId).notifier).terminarItem(item.id),
          child: const Text('Terminar'),
        );
      case EstadoItemOrdenTrabajo.rechazado:
      case EstadoItemOrdenTrabajo.terminado:
        return const SizedBox.shrink();
    }
  }

  Future<void> _agregarItem(BuildContext context, String ordenTrabajoId) async {
    await showDialog<bool>(context: context, builder: (_) => EditorItemOrdenTrabajoDialog(ordenTrabajoId: ordenTrabajoId));
  }

  Future<void> _cotizarItem(BuildContext context, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => EditorItemOrdenTrabajoDialog(ordenTrabajoId: ordenTrabajoId, itemIdACotizar: item.id, descripcionExistente: item.descripcion),
    );
  }

  Future<void> _rechazarItem(BuildContext context, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => RechazarItemDialog(ordenTrabajoId: ordenTrabajoId, itemId: item.id, descripcionItem: item.descripcion),
    );
  }

  Future<void> _editarObservacion(BuildContext context, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => EditarObservacionDialog(ordenTrabajoId: ordenTrabajoId, itemId: item.id, observacionActual: item.observacion),
    );
  }

  Future<void> _asignarOperador(BuildContext context, String ordenTrabajoId, ItemOrdenTrabajoDetalle item) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => AsignarOperadorDialog(ordenTrabajoId: ordenTrabajoId, itemId: item.id, usuarioIdActual: item.asignadoAUsuarioId),
    );
  }

  Future<void> _cobrar(BuildContext context, WidgetRef ref, OrdenTrabajoDetalle orden) async {
    final cajas = await ref.read(tenancyRepositoryProvider).listarCajas();
    if (cajas.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La Empresa no tiene ninguna Caja/Sucursal configurada.')),
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CobrarOrdenTrabajoDialog(orden: orden, cajaId: cajas.first.cajaId),
    );
  }
}
