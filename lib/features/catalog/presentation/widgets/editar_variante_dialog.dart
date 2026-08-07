import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/producto_admin.dart';
import '../../domain/models/unidad_medida.dart';
import '../providers/catalog_admin_providers.dart';
import 'etiqueta_codigo_barras.dart';
import 'oferta_field.dart';
import 'promocion_grupo_field.dart';

/// A diferencia de EditarProductoDialog, no depende de CatalogFormController
/// — no hay cascada de clasificación que resolver, es un PUT directo.
class EditarVarianteDialog extends ConsumerStatefulWidget {
  const EditarVarianteDialog({super.key, required this.variante, required this.nombreProducto});

  final VarianteAdmin variante;

  /// Para armar la etiqueta al imprimir — VarianteAdmin no trae el Nombre,
  /// solo vive en el Producto padre (ver ProductoAdmin).
  final String nombreProducto;

  @override
  ConsumerState<EditarVarianteDialog> createState() => _EditarVarianteDialogState();
}

class _EditarVarianteDialogState extends ConsumerState<EditarVarianteDialog> {
  late final _precioController = TextEditingController(text: widget.variante.precioVenta.toString());
  late final _codigoBarrasController = TextEditingController(text: widget.variante.codigoBarras ?? '');
  late final _colorController = TextEditingController(text: widget.variante.color ?? '');
  late final _tallaController = TextEditingController(text: widget.variante.talla ?? '');
  late final _ubicacionController = TextEditingController(text: widget.variante.ubicacionFisica ?? '');
  late final _cantidadMinimaDescuentoController =
      TextEditingController(text: widget.variante.cantidadMinimaDescuentoVolumen?.toString() ?? '');
  late final _porcentajeDescuentoController =
      TextEditingController(text: widget.variante.porcentajeDescuentoVolumen?.toString() ?? '');
  PromocionGrupoValor _promocionGrupo = const PromocionGrupoValor();
  OfertaValor _oferta = const OfertaValor();
  late int _unidadMedida = widget.variante.unidadMedida;
  late bool _tieneCodigoPersistido = widget.variante.codigoBarras != null;
  bool _guardando = false;
  bool _generandoCodigo = false;
  String? _error;

  @override
  void dispose() {
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
      title: Text('Editar Variante (${widget.variante.sku})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextField(
              key: const Key('editarPrecioVariante'),
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio de venta'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('editarUnidadMedidaVariante'),
              decoration: const InputDecoration(labelText: 'Unidad de medida'),
              value: _unidadMedida,
              items: UnidadMedida.values.map((u) => DropdownMenuItem(value: u.valor, child: Text(u.nombre))).toList(),
              onChanged: (valor) => setState(() => _unidadMedida = valor ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarCodigoBarrasVariante'),
              controller: _codigoBarrasController,
              decoration: const InputDecoration(labelText: 'Código de barras (opcional)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!_tieneCodigoPersistido)
                  OutlinedButton.icon(
                    key: const Key('generarCodigoBarrasVariante'),
                    onPressed: _generandoCodigo ? null : _generarCodigoBarras,
                    icon: _generandoCodigo
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.qr_code, size: 18),
                    label: const Text('Generar código de barras'),
                  ),
                if (_codigoBarrasController.text.trim().isNotEmpty) ...[
                  OutlinedButton.icon(
                    key: const Key('imprimirEtiquetaConPrecioVariante'),
                    onPressed: () => _imprimirEtiqueta(mostrarPrecio: true),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimir con precio'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('imprimirEtiquetaSinPrecioVariante'),
                    onPressed: () => _imprimirEtiqueta(mostrarPrecio: false),
                    icon: const Icon(Icons.print_disabled, size: 18),
                    label: const Text('Imprimir sin precio'),
                  ),
                ],
              ],
            ),
            if (_codigoBarrasController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: VistaPreviaEtiqueta(
                  nombre: widget.nombreProducto,
                  sku: widget.variante.sku,
                  precioVenta: widget.variante.precioVenta,
                  codigoBarras: _codigoBarrasController.text.trim(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarColorVariante'),
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarTallaVariante'),
              controller: _tallaController,
              decoration: const InputDecoration(labelText: 'Talla (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarUbicacionVariante'),
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: 'Ubicación física (opcional)'),
            ),
            const SizedBox(height: 12),
            Text('Descuento por volumen (opcional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            TextField(
              key: const Key('editarCantidadMinimaDescuentoVariante'),
              controller: _cantidadMinimaDescuentoController,
              decoration: const InputDecoration(labelText: 'Cantidad mínima'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editarPorcentajeDescuentoVariante'),
              controller: _porcentajeDescuentoController,
              decoration: const InputDecoration(labelText: '% de descuento'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Text('Promoción por grupo (opcional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            PromocionGrupoField(
              cantidadPorGrupoInicial: widget.variante.cantidadPorGrupoPromocion,
              porcentajeDescuentoUnidadInicial: widget.variante.porcentajeDescuentoUnidadPromocion,
              onChanged: (valor) => _promocionGrupo = valor,
            ),
            const SizedBox(height: 12),
            Text('Precio de oferta (opcional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            OfertaField(
              precioOfertaInicial: widget.variante.precioOferta,
              ofertaDesdeInicial: widget.variante.ofertaDesde,
              ofertaHastaInicial: widget.variante.ofertaHasta,
              onChanged: (valor) => _oferta = valor,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('guardarEdicionVariante'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio < 0) {
      setState(() => _error = 'Ingresa un precio válido');
      return;
    }

    final cantidadMinimaTexto = _cantidadMinimaDescuentoController.text.trim();
    final porcentajeTexto = _porcentajeDescuentoController.text.trim();
    if (cantidadMinimaTexto.isEmpty != porcentajeTexto.isEmpty) {
      setState(() => _error = 'Completa ambos campos del descuento por volumen, o deja los dos vacíos');
      return;
    }

    if (cantidadMinimaTexto.isNotEmpty && _promocionGrupo.cantidadPorGrupo != null) {
      setState(() => _error = 'No puedes combinar el descuento por volumen con una promoción por grupo — elige solo uno.');
      return;
    }

    if (_oferta.precioOferta != null && (cantidadMinimaTexto.isNotEmpty || _promocionGrupo.cantidadPorGrupo != null)) {
      setState(() => _error = 'No puedes combinar el precio de oferta con el descuento por volumen ni la promoción por grupo — elige solo uno.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await ref.read(catalogAdminRepositoryProvider).actualizarVariante(
            varianteProductoId: widget.variante.varianteProductoId,
            precioVenta: precio,
            unidadMedida: _unidadMedida,
            codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
            color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
            talla: _tallaController.text.trim().isEmpty ? null : _tallaController.text.trim(),
            ubicacionFisica: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
            cantidadMinimaDescuentoVolumen: int.tryParse(cantidadMinimaTexto),
            porcentajeDescuentoVolumen: double.tryParse(porcentajeTexto),
            cantidadPorGrupoPromocion: _promocionGrupo.cantidadPorGrupo,
            porcentajeDescuentoUnidadPromocion: _promocionGrupo.porcentajeDescuentoUnidad,
            precioOferta: _oferta.precioOferta,
            ofertaDesde: _oferta.ofertaDesde,
            ofertaHasta: _oferta.ofertaHasta,
          );

      if (!mounted) return;
      ref.read(productosAdminProvider.notifier).cargar();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _generarCodigoBarras() async {
    setState(() => _generandoCodigo = true);

    final codigo = await ref.read(productosAdminProvider.notifier).generarCodigoBarras(widget.variante);

    if (!mounted) return;
    setState(() {
      _generandoCodigo = false;
      if (codigo != null) {
        _codigoBarrasController.text = codigo;
        _tieneCodigoPersistido = true;
      }
    });
  }

  Future<void> _imprimirEtiqueta({required bool mostrarPrecio}) async {
    final codigo = _codigoBarrasController.text.trim();
    if (codigo.isEmpty) return;

    try {
      await imprimirEtiquetaCodigoBarras(
        nombre: widget.nombreProducto,
        sku: widget.variante.sku,
        precioVenta: widget.variante.precioVenta,
        codigoBarras: codigo,
        mostrarPrecio: mostrarPrecio,
      );
    } catch (e, stackTrace) {
      debugPrint('Error al imprimir etiqueta: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la impresión: $e')),
      );
    }
  }
}
