import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/producto_admin.dart';
import '../providers/catalog_admin_providers.dart';
import '../widgets/afiche_ofertas.dart';

class _VarianteEnOferta {
  const _VarianteEnOferta({required this.producto, required this.variante});

  final ProductoAdmin producto;
  final VarianteAdmin variante;
}

String _sufijoColorTalla(VarianteAdmin variante) {
  final partes = [variante.color, variante.talla].whereType<String>();
  return partes.isEmpty ? '' : ' · ${partes.join(' · ')}';
}

/// Productos "convenientes para el Cliente" hoy, listos para imprimir un
/// afiche — no solo precioOferta, también descuento por volumen y
/// promoción por grupo (2x1, 4x3, etc.), mismos 3 tipos que se destacan en
/// la tarjeta del POS (a pedido explícito: "se consideran todos los
/// productos que están en oferta... que sea conveniente para un cliente").
/// Filtra sobre el mismo listado admin que ProductosAdminScreen
/// (`productosAdminProvider`, ya trae todo el catálogo) usando
/// VarianteAdmin.tienePromocion en vez de pedir un endpoint nuevo, ya que
/// el catálogo de una PyME es chico.
class ProductosOfertaScreen extends ConsumerStatefulWidget {
  const ProductosOfertaScreen({super.key});

  @override
  ConsumerState<ProductosOfertaScreen> createState() => _ProductosOfertaScreenState();
}

class _ProductosOfertaScreenState extends ConsumerState<ProductosOfertaScreen> {
  final _busquedaController = TextEditingController();
  String _texto = '';

  /// Todas las Variantes en promoción están seleccionadas por defecto (el
  /// caso común es imprimir el afiche completo) — acá solo se registran
  /// las que el usuario deselecciona explícitamente, así que una Variante
  /// nueva (tras un refresh) queda seleccionada sin lógica extra.
  final Set<String> _deseleccionadas = {};

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<_VarianteEnOferta> _filtrar(List<_VarianteEnOferta> items) {
    final texto = _texto.trim().toLowerCase();
    if (texto.isEmpty) return items;
    return items.where((item) {
      if (item.producto.nombre.toLowerCase().contains(texto)) return true;
      return item.variante.sku.toLowerCase().contains(texto);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(productosAdminProvider);

    final todos = <_VarianteEnOferta>[
      for (final producto in estado.productos)
        for (final variante in producto.variantes)
          if (variante.tienePromocion) _VarianteEnOferta(producto: producto, variante: variante),
    ];
    final visibles = _filtrar(todos);
    final seleccionados =
        todos.where((item) => !_deseleccionadas.contains(item.variante.varianteProductoId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas y Promociones para Imprimir'),
        actions: [
          if (seleccionados.isNotEmpty)
            IconButton(
              key: const Key('ofertasImprimirBoton'),
              icon: const Icon(Icons.print),
              tooltip: 'Imprimir afiche de las seleccionadas',
              onPressed: () => imprimirAficheOfertas([
                for (final item in seleccionados)
                  ItemOferta(
                    nombreProducto: item.producto.nombre,
                    sku: item.variante.sku,
                    precioVenta: item.variante.precioVenta,
                    precioOferta: item.variante.ofertaVigente ? item.variante.precioOferta : null,
                    etiquetaPromocion: item.variante.etiquetaPromocion,
                  ),
              ]),
            ),
        ],
      ),
      body: estado.cargando && estado.productos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : todos.isEmpty
              ? const Center(child: Text('No hay Variantes con ofertas o promociones vigentes hoy.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        key: const Key('ofertasBusqueda'),
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto por nombre o SKU...',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('${seleccionados.length} de ${todos.length} seleccionadas'),
                          const Spacer(),
                          TextButton(
                            key: const Key('ofertasSeleccionarTodas'),
                            onPressed: () => setState(
                              () => _deseleccionadas
                                  .removeAll(visibles.map((item) => item.variante.varianteProductoId)),
                            ),
                            child: const Text('Todas'),
                          ),
                          TextButton(
                            key: const Key('ofertasDeseleccionarTodas'),
                            onPressed: () => setState(
                              () => _deseleccionadas
                                  .addAll(visibles.map((item) => item.variante.varianteProductoId)),
                            ),
                            child: const Text('Ninguna'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visibles.isEmpty
                          ? Center(child: Text('Sin resultados para "$_texto".'))
                          : RefreshIndicator(
                              onRefresh: () => ref.read(productosAdminProvider.notifier).cargar(),
                              child: ListView.separated(
                                itemCount: visibles.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = visibles[index];
                                  final variante = item.variante;
                                  final seleccionada = !_deseleccionadas.contains(variante.varianteProductoId);
                                  return CheckboxListTile(
                                    key: Key('ofertaItem_${variante.varianteProductoId}'),
                                    value: seleccionada,
                                    onChanged: (_) => setState(() {
                                      if (seleccionada) {
                                        _deseleccionadas.add(variante.varianteProductoId);
                                      } else {
                                        _deseleccionadas.remove(variante.varianteProductoId);
                                      }
                                    }),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(item.producto.nombre),
                                    subtitle: Text('${variante.sku}${_sufijoColorTalla(variante)}'),
                                    secondary: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: variante.ofertaVigente
                                          ? [
                                              Text(
                                                MonedaFormatter.formatear(variante.precioVenta),
                                                style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12),
                                              ),
                                              Text(
                                                MonedaFormatter.formatear(variante.precioOferta!),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.error,
                                                ),
                                              ),
                                            ]
                                          : [
                                              Text(MonedaFormatter.formatear(variante.precioVenta)),
                                              Text(
                                                variante.etiquetaPromocion ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
