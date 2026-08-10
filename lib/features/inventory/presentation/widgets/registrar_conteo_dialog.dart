import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show catalogRepositoryProvider;
import '../providers/inventory_providers.dart';

/// Buscar un Producto y pedir la Cantidad Contada — CantidadSistema la
/// calcula el servidor (snapshot al momento del conteo, ver
/// RegistrarConteoCommandHandler), no se pide acá.
class RegistrarConteoDialog extends ConsumerStatefulWidget {
  const RegistrarConteoDialog({super.key, required this.tomaId});

  final String tomaId;

  @override
  ConsumerState<RegistrarConteoDialog> createState() => _RegistrarConteoDialogState();
}

class _RegistrarConteoDialogState extends ConsumerState<RegistrarConteoDialog> {
  final _busquedaController = TextEditingController();
  final _cantidadController = TextEditingController();
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
      title: const Text('Registrar conteo'),
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
                  key: const Key('registrarConteoBusqueda'),
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
                      key: Key('registrarConteoResultado_${producto.varianteProductoId}'),
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
                  key: const Key('registrarConteoCantidad'),
                  controller: _cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad contada'),
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
            key: const Key('registrarConteoConfirmar'),
            onPressed: _guardando ? null : _registrar,
            child: _guardando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Registrar'),
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

  Future<void> _registrar() async {
    final cantidad = double.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad < 0) {
      setState(() => _error = 'La cantidad contada no puede ser negativa.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref
        .read(tomaInventarioDetalleProvider(widget.tomaId).notifier)
        .registrarConteo(varianteProductoId: _seleccionado!.varianteProductoId, cantidadContada: cantidad);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(tomaInventarioDetalleProvider(widget.tomaId)).error ?? 'No se pudo registrar el conteo.';
      });
    }
  }
}
