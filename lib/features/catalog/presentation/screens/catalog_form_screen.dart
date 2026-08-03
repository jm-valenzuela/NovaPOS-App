import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_admin_providers.dart';
import '../providers/catalog_form_providers.dart';
import '../widgets/clasificacion_cascade.dart';

const _unidadesMedida = [
  (valor: 0, nombre: 'Unidad'),
  (valor: 1, nombre: 'Kilogramo'),
  (valor: 2, nombre: 'Litro'),
];

/// Crea un Producto y su primera Variante juntos (mismo criterio que
/// CrearProductoCommand en el backend) — editar Producto/Variantes
/// existentes se hace con diálogos más chicos desde ProductosAdminScreen,
/// no en esta pantalla.
class CatalogFormScreen extends ConsumerStatefulWidget {
  const CatalogFormScreen({super.key});

  @override
  ConsumerState<CatalogFormScreen> createState() => _CatalogFormScreenState();
}

class _CatalogFormScreenState extends ConsumerState<CatalogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _skuController = TextEditingController();
  final _precioController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _colorController = TextEditingController();
  final _tallaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  int _unidadMedida = 0;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _skuController.dispose();
    _precioController.dispose();
    _codigoBarrasController.dispose();
    _colorController.dispose();
    _tallaController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(catalogFormProvider);

    ref.listen(catalogFormProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      if (actual.resultado != null && previo?.resultado == null) {
        ref.read(productosAdminProvider.notifier).cargar();
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Producto', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('nombreProducto'),
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('descripcionProducto'),
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 20),
              Text('Clasificación', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const ClasificacionCascade(),
              const SizedBox(height: 20),
              Text('Primera Variante', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('skuVariante'),
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El SKU es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('precioVariante'),
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio de venta'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final numero = double.tryParse(v ?? '');
                  if (numero == null || numero < 0) return 'Ingresa un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const Key('unidadMedidaVariante'),
                decoration: const InputDecoration(labelText: 'Unidad de medida'),
                value: _unidadMedida,
                items: _unidadesMedida
                    .map((u) => DropdownMenuItem(value: u.valor, child: Text(u.nombre)))
                    .toList(),
                onChanged: (valor) => setState(() => _unidadMedida = valor ?? 0),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('codigoBarrasVariante'),
                controller: _codigoBarrasController,
                decoration: const InputDecoration(labelText: 'Código de barras (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('colorVariante'),
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tallaVariante'),
                controller: _tallaController,
                decoration: const InputDecoration(labelText: 'Talla (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('ubicacionVariante'),
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación física (opcional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submitCrearProducto'),
                  onPressed: (estado.guardando || !estado.clasificacionCompleta) ? null : _enviar,
                  child: estado.guardando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Crear Producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(catalogFormProvider.notifier).crearProducto(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
          sku: _skuController.text.trim(),
          precioVenta: double.parse(_precioController.text),
          unidadMedida: _unidadMedida,
          codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
          color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
          talla: _tallaController.text.trim().isEmpty ? null : _tallaController.text.trim(),
          ubicacionFisica: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        );
  }
}
