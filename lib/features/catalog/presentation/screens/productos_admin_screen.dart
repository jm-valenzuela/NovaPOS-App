import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/clasificacion.dart';
import '../../domain/models/producto_admin.dart';
import '../providers/catalog_admin_providers.dart';
import '../widgets/editar_producto_dialog.dart';
import '../widgets/editar_variante_dialog.dart';
import 'catalog_form_screen.dart';

class ProductosAdminScreen extends ConsumerStatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  ConsumerState<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends ConsumerState<ProductosAdminScreen> {
  final _busquedaController = TextEditingController();
  String _texto = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Filtro local, no una llamada al backend — a diferencia de la
  /// búsqueda del POS (que pagina sobre un catálogo potencialmente
  /// grande), acá ya se cargó la lista completa de una vez (ver
  /// ProductosAdminController: "el catálogo de una PyME es chico"), así
  /// que filtrar en memoria por nombre, SKU, código de barras o
  /// Departamento es instantáneo y no necesita debounce ni un endpoint
  /// nuevo — mismo criterio combinado que las tabs de categoría del POS.
  List<ProductoAdmin> _filtrar(List<ProductoAdmin> productos, String? departamentoId) {
    final texto = _texto.trim().toLowerCase();
    return productos.where((p) {
      if (departamentoId != null && p.departamentoId != departamentoId) return false;
      if (texto.isEmpty) return true;
      if (p.nombre.toLowerCase().contains(texto)) return true;
      return p.variantes.any((v) =>
          v.sku.toLowerCase().contains(texto) || (v.codigoBarras?.toLowerCase().contains(texto) ?? false));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(productosAdminProvider);
    final departamentosAsync = ref.watch(departamentosAdminProvider);
    final departamentoSeleccionado = ref.watch(departamentoAdminSeleccionadoProvider);
    final productosFiltrados = _filtrar(estado.productos, departamentoSeleccionado);

    ref.listen(productosAdminProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const Key('catalogoBusqueda'),
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar producto por nombre, SKU o código de barras...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _texto.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _texto = '');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (texto) => setState(() => _texto = texto),
            ),
          ),
          departamentosAsync.when(
            data: (departamentos) => departamentos.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TabsDepartamentos(
                      departamentos: departamentos,
                      seleccionado: departamentoSeleccionado,
                      onSeleccionar: (departamentoId) =>
                          ref.read(departamentoAdminSeleccionadoProvider.notifier).state = departamentoId,
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
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
                      : productosFiltrados.isEmpty
                          ? ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(_texto.isEmpty
                                        ? 'Sin resultados en este Departamento.'
                                        : 'Sin resultados para "$_texto".'),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];
                                return _ProductoTile(
                                  key: Key('catalogoProducto_${producto.productoId}'),
                                  producto: producto,
                                );
                              },
                            ),
            ),
          ),
        ],
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

/// Mismo patrón que _TabsCategorias del POS (chips horizontales con
/// "Todos" al inicio), pero con los colores por defecto de Material en
/// vez del tema navy del POS — esta pantalla no comparte esa identidad
/// visual.
class _TabsDepartamentos extends StatelessWidget {
  const _TabsDepartamentos({required this.departamentos, required this.seleccionado, required this.onSeleccionar});

  final List<Departamento> departamentos;
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              key: const Key('catalogoDepartamentoTodos'),
              label: const Text('Todos'),
              selected: seleccionado == null,
              onSelected: (_) => onSeleccionar(null),
            ),
          ),
          for (final departamento in departamentos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                key: Key('catalogoDepartamento_${departamento.id}'),
                label: Text(departamento.nombre),
                selected: seleccionado == departamento.id,
                onSelected: (_) => onSeleccionar(departamento.id),
              ),
            ),
        ],
      ),
    );
  }
}
