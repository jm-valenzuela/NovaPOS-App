import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show tenancyRepositoryProvider;
import '../../domain/models/proveedor.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';

/// Elige Proveedor + Forma de Pago y crea la Orden — la Bodega destino se
/// resuelve sola (misma Bodega de venta de la primera Caja de la Empresa,
/// ver TenancyRepository.obtenerBodegaVenta) porque el backend hoy no
/// expone un selector de Bodegas propio (ver README, gap conocido).
/// Devuelve el Id de la Orden creada, o null si se canceló/falló.
class NuevaOrdenCompraDialog extends ConsumerStatefulWidget {
  const NuevaOrdenCompraDialog({super.key});

  @override
  ConsumerState<NuevaOrdenCompraDialog> createState() => _NuevaOrdenCompraDialogState();
}

class _NuevaOrdenCompraDialogState extends ConsumerState<NuevaOrdenCompraDialog> {
  final _busquedaController = TextEditingController();
  List<ProveedorResumen> _resultados = [];
  ProveedorResumen? _seleccionado;
  FormaPago _formaPago = FormaPago.contado;
  bool _buscando = false;
  bool _creando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Orden de Compra'),
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
                  key: const Key('nuevaOrdenBusquedaProveedor'),
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar Proveedor',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscando ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                  ),
                  onChanged: _buscar,
                ),
                const SizedBox(height: 8),
                ..._resultados.map((proveedor) => ListTile(
                      key: Key('nuevaOrdenProveedor_${proveedor.id}'),
                      title: Text(proveedor.nombre),
                      subtitle: Text(proveedor.rut),
                      onTap: () => setState(() => _seleccionado = proveedor),
                    )),
              ] else ...[
                ListTile(
                  title: Text(_seleccionado!.nombre),
                  subtitle: Text(_seleccionado!.rut),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _seleccionado = null)),
                ),
                const SizedBox(height: 8),
                SegmentedButton<FormaPago>(
                  segments: const [
                    ButtonSegment(value: FormaPago.contado, label: Text('Contado')),
                    ButtonSegment(value: FormaPago.credito, label: Text('Crédito')),
                  ],
                  selected: {_formaPago},
                  onSelectionChanged: (seleccion) => setState(() => _formaPago = seleccion.first),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        if (_seleccionado != null)
          FilledButton(
            key: const Key('nuevaOrdenConfirmar'),
            onPressed: _creando ? null : _crear,
            child: _creando
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Crear'),
          ),
      ],
    );
  }

  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);
    try {
      final resultados = await ref.read(purchasingRepositoryProvider).buscarProveedores(texto: texto.isEmpty ? null : texto);
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

  Future<void> _crear() async {
    setState(() {
      _creando = true;
      _error = null;
    });

    try {
      final cajas = await ref.read(tenancyRepositoryProvider).listarCajas();
      if (cajas.isEmpty) throw Exception('La Empresa no tiene ninguna Caja/Sucursal configurada.');
      final bodega = await ref.read(tenancyRepositoryProvider).obtenerBodegaVenta(cajas.first.sucursalId);
      if (bodega == null) throw Exception('La Sucursal no tiene una Bodega de venta configurada.');

      final ordenCompraId = await ref.read(purchasingRepositoryProvider).crearOrdenCompra(
            proveedorId: _seleccionado!.id,
            bodegaDestinoId: bodega.bodegaId,
            formaPago: _formaPago,
          );

      if (!mounted) return;
      Navigator.of(context).pop(ordenCompraId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creando = false;
        _error = e.toString();
      });
    }
  }
}
