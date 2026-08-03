import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/producto_admin.dart';
import '../providers/catalog_admin_providers.dart';
import '../providers/catalog_form_providers.dart';
import 'clasificacion_cascade.dart';

class EditarProductoDialog extends ConsumerStatefulWidget {
  const EditarProductoDialog({super.key, required this.producto});

  final ProductoAdmin producto;

  @override
  ConsumerState<EditarProductoDialog> createState() => _EditarProductoDialogState();
}

class _EditarProductoDialogState extends ConsumerState<EditarProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.producto.nombre);
  late final _descripcionController = TextEditingController(text: widget.producto.descripcion ?? '');
  bool _cambiarClasificacion = false;
  bool _inicializado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(catalogFormProvider);

    if (!_inicializado) {
      _inicializado = true;
      Future.microtask(() => ref
          .read(catalogFormProvider.notifier)
          .inicializarClasificacionExistente(subclaseId: widget.producto.subclaseId, marcaId: widget.producto.marcaId));
    }

    ref.listen(catalogFormProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return AlertDialog(
      title: const Text('Editar Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('editarNombreProducto'),
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editarDescripcionProducto'),
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 12),
              if (!_cambiarClasificacion) ...[
                Text('Categoría: ${widget.producto.subclaseNombre} · ${widget.producto.marcaNombre}'),
                TextButton(
                  key: const Key('cambiarClasificacion'),
                  onPressed: () => setState(() => _cambiarClasificacion = true),
                  child: const Text('Cambiar clasificación'),
                ),
              ] else
                const ClasificacionCascade(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('guardarEdicionProducto'),
          onPressed: estado.guardando ? null : _guardar,
          child: estado.guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(catalogFormProvider.notifier).actualizarProducto(
          productoId: widget.producto.productoId,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        );

    if (ok && mounted) {
      ref.read(productosAdminProvider.notifier).cargar();
      Navigator.of(context).pop();
    }
  }
}
