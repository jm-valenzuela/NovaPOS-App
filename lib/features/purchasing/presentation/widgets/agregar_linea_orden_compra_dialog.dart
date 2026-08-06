import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show catalogRepositoryProvider;
import '../providers/purchasing_providers.dart';

/// Buscar un Producto y pedir Cantidad/CostoUnitario, en un solo diálogo —
/// reutiliza CatalogRepository.buscarProductos (mismo buscador del POS,
/// ver pos_providers.dart) en vez de duplicar la lógica de búsqueda.
class AgregarLineaOrdenCompraDialog extends ConsumerStatefulWidget {
  const AgregarLineaOrdenCompraDialog({super.key, required this.ordenCompraId});

  final String ordenCompraId;

  @override
  ConsumerState<AgregarLineaOrdenCompraDialog> createState() => _AgregarLineaOrdenCompraDialogState();
}

class _AgregarLineaOrdenCompraDialogState extends ConsumerState<AgregarLineaOrdenCompraDialog> {
  final _busquedaController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _costoController = TextEditingController();
  List<ProductoVendible> _resultados = [];
  ProductoVendible? _seleccionado;
  bool _buscando = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _busquedaController.dispose();
    _cantidadController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar línea'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              if (_seleccionado == null) ...[
                TextField(
                  key: const Key('agregarLineaBusqueda'),
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscando ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                  ),
                  onSubmitted: _buscar,
                  onChanged: (texto) => _buscar(texto),
                ),
                const SizedBox(height: 8),
                ..._resultados.map((producto) => ListTile(
                      key: Key('agregarLineaResultado_${producto.varianteProductoId}'),
                      title: Text(producto.nombreProducto),
                      subtitle: Text(producto.sku),
                      onTap: () => setState(() => _seleccionado = producto),
                    )),
              ] else ...[
                ListTile(
                  title: Text(_seleccionado!.nombreProducto),
                  subtitle: Text(_seleccionado!.sku),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _seleccionado = null)),
                ),
                TextField(
                  key: const Key('agregarLineaCantidad'),
                  controller: _cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('agregarLineaCosto'),
                  controller: _costoController,
                  decoration: const InputDecoration(labelText: 'Costo unitario'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        if (_seleccionado != null)
          FilledButton(
            key: const Key('agregarLineaConfirmar'),
            onPressed: _guardando ? null : _agregar,
            child: _guardando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Agregar'),
          ),
      ],
    );
  }

  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);
    try {
      final resultados = await ref.read(catalogRepositoryProvider).buscarProductos(texto: texto);
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscando = false);
    }
  }

  Future<void> _agregar() async {
    final cantidad = double.tryParse(_cantidadController.text.trim());
    final costo = double.tryParse(_costoController.text.trim());
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor a cero.');
      return;
    }
    if (costo == null || costo < 0) {
      setState(() => _error = 'El costo unitario no puede ser negativo.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(ordenCompraDetalleProvider(widget.ordenCompraId).notifier).agregarLinea(
          varianteProductoId: _seleccionado!.varianteProductoId,
          cantidad: cantidad,
          costoUnitario: costo,
        );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(ordenCompraDetalleProvider(widget.ordenCompraId)).error ?? 'No se pudo agregar la línea.';
      });
    }
  }
}
