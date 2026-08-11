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

/// Productos en oferta hoy, listos para imprimir un afiche — filtra sobre
/// el mismo listado admin que ProductosAdminScreen (`productosAdminProvider`,
/// ya trae todo el catálogo) usando VarianteAdmin.ofertaVigente en vez de
/// pedir un endpoint nuevo, ya que el catálogo de una PyME es chico.
class ProductosOfertaScreen extends ConsumerWidget {
  const ProductosOfertaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(productosAdminProvider);

    final items = <_VarianteEnOferta>[
      for (final producto in estado.productos)
        for (final variante in producto.variantes)
          if (variante.ofertaVigente) _VarianteEnOferta(producto: producto, variante: variante),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas para Imprimir'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              key: const Key('ofertasImprimirBoton'),
              icon: const Icon(Icons.print),
              tooltip: 'Imprimir afiche de ofertas',
              onPressed: () => imprimirAficheOfertas([
                for (final item in items)
                  ItemOferta(
                    nombreProducto: item.producto.nombre,
                    sku: item.variante.sku,
                    precioVenta: item.variante.precioVenta,
                    precioOferta: item.variante.precioOferta!,
                  ),
              ]),
            ),
        ],
      ),
      body: estado.cargando && estado.productos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No hay Variantes con oferta vigente hoy.'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(productosAdminProvider.notifier).cargar(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        key: Key('ofertaItem_${item.variante.varianteProductoId}'),
                        title: Text(item.producto.nombre),
                        subtitle: Text('${item.variante.sku}${_sufijoColorTalla(item.variante)}'),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              MonedaFormatter.formatear(item.variante.precioVenta),
                              style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12),
                            ),
                            Text(
                              MonedaFormatter.formatear(item.variante.precioOferta!),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
