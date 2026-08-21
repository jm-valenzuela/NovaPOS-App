import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/domain/models/anticipo_disponible_para_pago.dart';
import '../../../sales/domain/models/stock_insuficiente_exception.dart';
import '../../../sales/domain/models/venta_enums.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show salesRepositoryProvider;
import '../../../sales/presentation/widgets/checkout_dialog.dart';
import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';

/// Arma una Venta real a partir de las líneas de los Ítems Terminados de
/// la Orden de Trabajo (los únicos que quedan por cobrar — un Ítem
/// Rechazado nunca llega acá, ver OrdenTrabajo.RecalcularEstado) — cada
/// línea de Producto se agrega como una línea normal (precio real del
/// Catálogo), cada línea de Trabajo como una línea libre (ver
/// SalesRepository.agregarLineaLibre). Sin Cliente
/// completo a mano acá (solo Id/Nombre/Rut, ver OrdenTrabajoDetalle), el
/// cobro queda limitado a Boleta — Factura requeriría los datos
/// completos del Cliente (Giro/Dirección/Comuna), que esta pantalla no
/// tiene; se puede agregar más adelante si hace falta. Al confirmar la
/// Venta, vincula el VentaId a la Orden vía Entregar.
class CobrarOrdenTrabajoDialog extends ConsumerStatefulWidget {
  const CobrarOrdenTrabajoDialog({super.key, required this.orden, required this.cajaId});

  final OrdenTrabajoDetalle orden;
  final String cajaId;

  @override
  ConsumerState<CobrarOrdenTrabajoDialog> createState() => _CobrarOrdenTrabajoDialogState();
}

class _CobrarOrdenTrabajoDialogState extends ConsumerState<CobrarOrdenTrabajoDialog> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cobrar());
  }

  Future<void> _cobrar() async {
    setState(() => _error = null);

    try {
      final salesRepository = ref.read(salesRepositoryProvider);
      final ventaId = await salesRepository.crearVenta(cajaId: widget.cajaId, clienteId: widget.orden.clienteId);

      final itemsTerminados = widget.orden.items.where((i) => i.estado == EstadoItemOrdenTrabajo.terminado);
      for (final item in itemsTerminados) {
        for (final linea in item.lineas) {
          if (linea.tipo == TipoLineaOrdenTrabajo.producto) {
            await salesRepository.agregarLinea(
              ventaId: ventaId,
              varianteProductoId: linea.varianteProductoId!,
              cantidad: linea.cantidad ?? 1,
            );
          } else {
            await salesRepository.agregarLineaLibre(ventaId: ventaId, descripcion: linea.descripcion, monto: linea.monto);
          }
        }
      }

      if (!mounted) return;
      final resultadoCheckout = await showDialog<ResultadoCheckout>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckoutDialog(
          total: widget.orden.montoAprobado!,
          formaPago: FormaPago.contado,
          clienteSeleccionado: null,
          anticiposDisponibles: widget.orden.anticiposDisponiblesParaPago
              .map((a) => AnticipoDisponibleParaPago(id: a.id, monto: a.monto, etiquetaMedioPagoOriginal: a.medioPago.etiqueta))
              .toList(),
        ),
      );

      if (resultadoCheckout == null) {
        if (!mounted) return;
        Navigator.of(context).pop(false);
        return;
      }

      var permitirVentaSinStock = false;
      try {
        await salesRepository.confirmarVenta(
          ventaId: ventaId,
          tipoDocumento: resultadoCheckout.tipoDocumento,
          pagos: resultadoCheckout.pagos,
        );
      } on StockInsuficienteException catch (e) {
        if (!mounted) return;
        final continuar = await _mostrarStockInsuficiente(e);
        if (!mounted) return;
        if (continuar != true) {
          Navigator.of(context).pop(false);
          return;
        }
        permitirVentaSinStock = true;
        await salesRepository.confirmarVenta(
          ventaId: ventaId,
          tipoDocumento: resultadoCheckout.tipoDocumento,
          pagos: resultadoCheckout.pagos,
          permitirVentaSinStock: permitirVentaSinStock,
        );
      }

      final ok = await ref.read(ordenTrabajoDetalleProvider(widget.orden.id).notifier).entregar(ventaId);

      if (!mounted) return;
      Navigator.of(context).pop(ok);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<bool?> _mostrarStockInsuficiente(StockInsuficienteException error) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stock insuficiente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final linea in error.lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${linea.nombreProducto}: hay ${linea.cantidadDisponible.toStringAsFixed(0)}, pediste ${linea.cantidadPedida.toStringAsFixed(0)}'),
              ),
            const SizedBox(height: 8),
            const Text('¿Quieres vender igual? El stock quedará negativo hasta que lo corrijas con una entrada de inventario.'),
          ],
        ),
        actions: [
          TextButton(key: const Key('cobrarOtStockCancelar'), onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('cobrarOtStockContinuar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar de todas formas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cobrar Orden de Trabajo'),
      content: SizedBox(
        width: 320,
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  const Text('La Venta puede haber quedado a medio armar — reintenta o revisa el Punto de Venta.'),
                ],
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 16),
                  Expanded(child: Text('Armando la Venta...')),
                ],
              ),
      ),
      actions: _error == null
          ? []
          : [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cerrar')),
              FilledButton(key: const Key('cobrarOtReintentar'), onPressed: _cobrar, child: const Text('Reintentar')),
            ],
    );
  }
}
