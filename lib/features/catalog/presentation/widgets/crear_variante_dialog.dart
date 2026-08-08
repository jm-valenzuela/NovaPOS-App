import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/unidad_medida.dart';
import '../providers/catalog_admin_providers.dart';
import 'oferta_field.dart';
import 'promocion_grupo_field.dart';

/// Agrega una Variante adicional (ej. otro color/talla) a un Producto ya
/// existente — mismo criterio que EditarVarianteDialog (sin cascada de
/// clasificación, POST directo), pero requiere SKU (no editable después de
/// creada) y no ofrece generar/imprimir código de barras todavía: esas
/// acciones necesitan un varianteProductoId ya persistido, disponibles
/// recién editando la Variante una vez creada.
class CrearVarianteDialog extends ConsumerStatefulWidget {
  const CrearVarianteDialog(
      {super.key, required this.productoId, required this.nombreProducto});

  final String productoId;
  final String nombreProducto;

  @override
  ConsumerState<CrearVarianteDialog> createState() =>
      _CrearVarianteDialogState();
}

class _CrearVarianteDialogState extends ConsumerState<CrearVarianteDialog> {
  final _skuController = TextEditingController();
  final _precioController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _colorController = TextEditingController();
  final _tallaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _cantidadMinimaDescuentoController = TextEditingController();
  final _porcentajeDescuentoController = TextEditingController();
  PromocionGrupoValor _promocionGrupo = const PromocionGrupoValor();
  OfertaValor _oferta = const OfertaValor();
  int _unidadMedida = 0;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _skuController.dispose();
    _precioController.dispose();
    _codigoBarrasController.dispose();
    _colorController.dispose();
    _tallaController.dispose();
    _ubicacionController.dispose();
    _cantidadMinimaDescuentoController.dispose();
    _porcentajeDescuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Variante (${widget.nombreProducto})'),
      content: SingleChildScrollView(
        // padding derecho extra — sin él, la barra de scroll (fija al borde
        // del SingleChildScrollView) queda pegada al borde redondeado del
        // diálogo.
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Separación mínima antes del primer campo — sin ella, con un
              // título largo (nombre de Producto) que ocupa 2 líneas, el label
              // flotante del primer TextField queda pegado al borde del
              // diálogo y se ve recortado.
              const SizedBox(height: 4),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              TextField(
                key: const Key('crearSkuVariante'),
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearPrecioVariante'),
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio de venta'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const Key('crearUnidadMedidaVariante'),
                decoration:
                    const InputDecoration(labelText: 'Unidad de medida'),
                value: _unidadMedida,
                items: UnidadMedida.values
                    .map((u) =>
                        DropdownMenuItem(value: u.valor, child: Text(u.nombre)))
                    .toList(),
                onChanged: (valor) =>
                    setState(() => _unidadMedida = valor ?? 0),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearCodigoBarrasVariante'),
                controller: _codigoBarrasController,
                decoration: const InputDecoration(
                    labelText: 'Código de barras (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearColorVariante'),
                controller: _colorController,
                decoration:
                    const InputDecoration(labelText: 'Color (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearTallaVariante'),
                controller: _tallaController,
                decoration:
                    const InputDecoration(labelText: 'Talla (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearUbicacionVariante'),
                controller: _ubicacionController,
                decoration: const InputDecoration(
                    labelText: 'Ubicación física (opcional)'),
              ),
              const SizedBox(height: 12),
              Text('Descuento por volumen (opcional)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              TextField(
                key: const Key('crearCantidadMinimaDescuentoVariante'),
                controller: _cantidadMinimaDescuentoController,
                decoration: const InputDecoration(labelText: 'Cantidad mínima'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('crearPorcentajeDescuentoVariante'),
                controller: _porcentajeDescuentoController,
                decoration: const InputDecoration(labelText: '% de descuento'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Text('Promoción por grupo (opcional)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              PromocionGrupoField(
                  onChanged: (valor) => _promocionGrupo = valor),
              const SizedBox(height: 12),
              Text('Precio de oferta (opcional)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              OfertaField(onChanged: (valor) => _oferta = valor),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          key: const Key('guardarCrearVariante'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final sku = _skuController.text.trim();
    if (sku.isEmpty) {
      setState(() => _error = 'El SKU es obligatorio');
      return;
    }

    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio < 0) {
      setState(() => _error = 'Ingresa un precio válido');
      return;
    }

    final cantidadMinimaTexto = _cantidadMinimaDescuentoController.text.trim();
    final porcentajeTexto = _porcentajeDescuentoController.text.trim();
    if (cantidadMinimaTexto.isEmpty != porcentajeTexto.isEmpty) {
      setState(() => _error =
          'Completa ambos campos del descuento por volumen, o deja los dos vacíos');
      return;
    }

    if (cantidadMinimaTexto.isNotEmpty &&
        _promocionGrupo.cantidadPorGrupo != null) {
      setState(() => _error =
          'No puedes combinar el descuento por volumen con una promoción por grupo — elige solo uno.');
      return;
    }

    if (_oferta.precioOferta != null &&
        (cantidadMinimaTexto.isNotEmpty ||
            _promocionGrupo.cantidadPorGrupo != null)) {
      setState(() => _error =
          'No puedes combinar el precio de oferta con el descuento por volumen ni la promoción por grupo — elige solo uno.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(productosAdminProvider.notifier).crearVariante(
          productoId: widget.productoId,
          sku: sku,
          precioVenta: precio,
          unidadMedida: _unidadMedida,
          codigoBarras: _codigoBarrasController.text.trim().isEmpty
              ? null
              : _codigoBarrasController.text.trim(),
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          talla: _tallaController.text.trim().isEmpty
              ? null
              : _tallaController.text.trim(),
          ubicacionFisica: _ubicacionController.text.trim().isEmpty
              ? null
              : _ubicacionController.text.trim(),
          cantidadMinimaDescuentoVolumen: int.tryParse(cantidadMinimaTexto),
          porcentajeDescuentoVolumen: double.tryParse(porcentajeTexto),
          cantidadPorGrupoPromocion: _promocionGrupo.cantidadPorGrupo,
          porcentajeDescuentoUnidadPromocion:
              _promocionGrupo.porcentajeDescuentoUnidad,
          precioOferta: _oferta.precioOferta,
          ofertaDesde: _oferta.ofertaDesde,
          ofertaHasta: _oferta.ofertaHasta,
        );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(productosAdminProvider).error ??
            'No se pudo crear la Variante.';
      });
    }
  }
}
