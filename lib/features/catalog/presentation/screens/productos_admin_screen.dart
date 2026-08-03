import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/producto_admin.dart';
import '../providers/catalog_admin_providers.dart';
import '../widgets/editar_producto_dialog.dart';
import '../widgets/editar_variante_dialog.dart';
import 'catalog_form_screen.dart';

class ProductosAdminScreen extends ConsumerWidget {
  const ProductosAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(productosAdminProvider);

    ref.listen(productosAdminProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productosAdminProvider.notifier).cargar(),
        child: estado.cargando && estado.productos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.productos.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No hay Productos creados todavía.')),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: estado.productos.length,
                    itemBuilder: (context, index) {
                      final producto = estado.productos[index];
                      return _ProductoTile(key: Key('catalogoProducto_${producto.productoId}'), producto: producto);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('catalogoNuevoProducto'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CatalogFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductoTile extends ConsumerWidget {
  const _ProductoTile({super.key, required this.producto});

  final ProductoAdmin producto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(producto.nombre, style: TextStyle(decoration: producto.activo ? null : TextDecoration.lineThrough)),
        subtitle: Text('${producto.subclaseNombre} · ${producto.marcaNombre}'),
        leading: Switch(
          key: Key('catalogoProductoActivo_${producto.productoId}'),
          value: producto.activo,
          onChanged: (_) => ref.read(productosAdminProvider.notifier).alternarProducto(producto),
        ),
        trailing: IconButton(
          key: Key('catalogoEditarProducto_${producto.productoId}'),
          icon: const Icon(Icons.edit),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => EditarProductoDialog(producto: producto),
          ),
        ),
        children: producto.variantes.isEmpty
            ? [const Padding(padding: EdgeInsets.all(12), child: Text('Sin Variantes'))]
            : producto.variantes.map((variante) => _VarianteTile(variante: variante)).toList(),
      ),
    );
  }
}

class _VarianteTile extends ConsumerWidget {
  const _VarianteTile({required this.variante});

  final VarianteAdmin variante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('catalogoVariante_${variante.varianteProductoId}'),
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text(
        '${variante.sku} — ${MonedaFormatter.formatear(variante.precioVenta)}',
        style: TextStyle(decoration: variante.activa ? null : TextDecoration.lineThrough),
      ),
      subtitle: [variante.color, variante.talla].whereType<String>().isEmpty
          ? null
          : Text([variante.color, variante.talla].whereType<String>().join(' · ')),
      leading: Switch(
        key: Key('catalogoVarianteActiva_${variante.varianteProductoId}'),
        value: variante.activa,
        onChanged: (_) => ref.read(productosAdminProvider.notifier).alternarVariante(variante),
      ),
      trailing: IconButton(
        key: Key('catalogoEditarVariante_${variante.varianteProductoId}'),
        icon: const Icon(Icons.edit),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => EditarVarianteDialog(variante: variante),
        ),
      ),
    );
  }
}
