import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show catalogRepositoryProvider;
import '../providers/inventory_providers.dart';

/// Buscar un Producto y pedir la Cantidad a trasladar — mismo patrón que
/// AgregarLineaOrdenCompraDialog en Purchasing.
class AgregarLineaTrasladoDialog extends ConsumerStatefulWidget {
  const AgregarLineaTrasladoDialog({super.key, required this.trasladoId});

  final String trasladoId;

  @override
  ConsumerState<AgregarLineaTrasladoDialog> createState() => _AgregarLineaTrasladoDialogState();
}

class _AgregarLineaTrasladoDialogState extends ConsumerState<AgregarLineaTrasladoDialog> {
  final _busquedaController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  List<ProductoVendible> _resultados = [];
  ProductoVendible? _seleccionado;
  bool _buscando = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _busquedaController.dispose();
    _cantidadController.dispose();
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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (_seleccionado == null) ...[
                TextField(
                  key: const Key('agregarLineaTrasladoBusqueda'),
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscando
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                  ),
                  onSubmitted: _buscar,
                  onChanged: _buscar,
                ),
                const SizedBox(height: 8),
                ..._resultados.map((producto) => ListTile(
                      key: Key('agregarLineaTrasladoResultado_${producto.varianteProductoId}'),
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
                  key: const Key('agregarLineaTrasladoCantidad'),
                  controller: _cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
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
            key: const Key('agregarLineaTrasladoConfirmar'),
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
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor a cero.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref
        .read(trasladoDetalleProvider(widget.trasladoId).notifier)
        .agregarLinea(varianteProductoId: _seleccionado!.varianteProductoId, cantidad: cantidad);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(trasladoDetalleProvider(widget.trasladoId)).error ?? 'No se pudo agregar la línea.';
      });
    }
  }
}
