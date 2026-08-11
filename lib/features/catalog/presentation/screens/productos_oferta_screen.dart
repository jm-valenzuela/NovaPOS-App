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
class ProductosOfertaScreen extends ConsumerWidget {
  const ProductosOfertaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(productosAdminProvider);

    final items = <_VarianteEnOferta>[
      for (final producto in estado.productos)
        for (final variante in producto.variantes)
          if (variante.tienePromocion) _VarianteEnOferta(producto: producto, variante: variante),
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
                    precioOferta: item.variante.ofertaVigente ? item.variante.precioOferta : null,
                    etiquetaPromocion: item.variante.etiquetaPromocion,
                  ),
              ]),
            ),
        ],
      ),
      body: estado.cargando && estado.productos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No hay Variantes con ofertas o promociones vigentes hoy.'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(productosAdminProvider.notifier).cargar(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final variante = item.variante;
                      return ListTile(
                        key: Key('ofertaItem_${variante.varianteProductoId}'),
                        title: Text(item.producto.nombre),
                        subtitle: Text('${variante.sku}${_sufijoColorTalla(variante)}'),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (variante.ofertaVigente) ...[
                              Text(
                                MonedaFormatter.formatear(variante.precioVenta),
                                style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12),
                              ),
                              Text(
                                MonedaFormatter.formatear(variante.precioOferta!),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                              ),
                            ] else ...[
                              Text(MonedaFormatter.formatear(variante.precioVenta)),
                              Text(
                                variante.etiquetaPromocion ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
