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

  /// Ninguna Variante viene seleccionada por defecto — el usuario elige
  /// explícitamente cuáles imprimir (a pedido explícito: "que no aparezcan
  /// todos seleccionados").
  final Set<String> _seleccionadas = {};

  /// Estado local, no el `departamentoAdminSeleccionadoProvider` compartido
  /// con ProductosAdminScreen — el filtro de esta pantalla es independiente
  /// del de Catálogo.
  String? _departamentoSeleccionado;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<_VarianteEnOferta> _filtrar(List<_VarianteEnOferta> items) {
    final texto = _texto.trim().toLowerCase();
    return items.where((item) {
      if (_departamentoSeleccionado != null && item.producto.departamentoId != _departamentoSeleccionado) {
        return false;
      }
      if (texto.isEmpty) return true;
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
    final departamentos = <String, String>{
      for (final item in todos) item.producto.departamentoId: item.producto.departamentoNombre,
    };
    final visibles = _filtrar(todos);
    final seleccionados = todos.where((item) => _seleccionadas.contains(item.variante.varianteProductoId)).toList();

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
                    if (departamentos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  key: const Key('ofertasDepartamentoTodos'),
                                  label: const Text('Todos'),
                                  selected: _departamentoSeleccionado == null,
                                  onSelected: (_) => setState(() => _departamentoSeleccionado = null),
                                ),
                              ),
                              for (final entry in departamentos.entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    key: Key('ofertasDepartamento_${entry.key}'),
                                    label: Text(entry.value),
                                    selected: _departamentoSeleccionado == entry.key,
                                    onSelected: (_) => setState(() => _departamentoSeleccionado = entry.key),
                                  ),
                                ),
                            ],
                          ),
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
                              () => _seleccionadas.addAll(visibles.map((item) => item.variante.varianteProductoId)),
                            ),
                            child: const Text('Todas'),
                          ),
                          TextButton(
                            key: const Key('ofertasDeseleccionarTodas'),
                            onPressed: () => setState(
                              () => _seleccionadas
                                  .removeAll(visibles.map((item) => item.variante.varianteProductoId)),
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
                                  final seleccionada = _seleccionadas.contains(variante.varianteProductoId);
                                  return CheckboxListTile(
                                    key: Key('ofertaItem_${variante.varianteProductoId}'),
                                    value: seleccionada,
                                    onChanged: (_) => setState(() {
                                      if (seleccionada) {
                                        _seleccionadas.remove(variante.varianteProductoId);
                                      } else {
                                        _seleccionadas.add(variante.varianteProductoId);
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
