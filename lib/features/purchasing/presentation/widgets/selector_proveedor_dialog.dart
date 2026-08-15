import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/proveedor.dart';
import '../providers/purchasing_providers.dart';
import 'nuevo_proveedor_rapido_dialog.dart';

/// Buscar-o-crear-rápido de Proveedor — mismo patrón que SelectorClienteDialog
/// (Sales), a pedido explícito del usuario: registrar una Factura Interna no
/// debe exigir pre-navegar a un Proveedor existente. Devuelve el
/// ProveedorResumen elegido, o null si se canceló.
class SelectorProveedorDialog extends ConsumerStatefulWidget {
  const SelectorProveedorDialog({super.key});

  @override
  ConsumerState<SelectorProveedorDialog> createState() => _SelectorProveedorDialogState();
}

class _SelectorProveedorDialogState extends ConsumerState<SelectorProveedorDialog> {
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(busquedaProveedoresProvider.notifier).buscar('');
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _crearProveedor(BuildContext context) async {
    final creado = await showDialog<ProveedorResumen>(
      context: context,
      builder: (_) => const NuevoProveedorRapidoDialog(),
    );
    if (creado == null || !context.mounted) return;
    Navigator.of(context).pop(creado);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(busquedaProveedoresProvider);

    return AlertDialog(
      title: const Text('Elegir Proveedor'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const Key('selectorProveedorBusqueda'),
              controller: _busquedaController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o RUT',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: estado.buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              onChanged: (texto) => ref.read(busquedaProveedoresProvider.notifier).buscar(texto),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: estado.resultados.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: estado.resultados.length,
                      itemBuilder: (context, index) {
                        final proveedor = estado.resultados[index];
                        return ListTile(
                          key: Key('selectorProveedorResultado_${proveedor.id}'),
                          title: Text(proveedor.nombre),
                          subtitle: Text(proveedor.rut),
                          onTap: () => Navigator.of(context).pop(proveedor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('selectorProveedorCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          key: const Key('selectorProveedorNuevo'),
          onPressed: () => _crearProveedor(context),
          child: const Text('Nuevo Proveedor'),
        ),
      ],
    );
  }
}
