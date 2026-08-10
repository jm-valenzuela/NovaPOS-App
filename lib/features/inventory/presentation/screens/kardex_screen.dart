import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show catalogRepositoryProvider;
import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../../domain/models/inventory_enums.dart';
import '../providers/inventory_providers.dart';

/// Tarjeta de Existencia (Kardex): elige Bodega + Producto y muestra el
/// historial de movimientos con el saldo que quedaba después de cada uno.
class KardexScreen extends ConsumerStatefulWidget {
  const KardexScreen({super.key});

  @override
  ConsumerState<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends ConsumerState<KardexScreen> {
  final _busquedaController = TextEditingController();
  BodegaResumen? _bodega;
  ProductoVendible? _producto;
  List<ProductoVendible> _resultados = [];
  bool _buscando = false;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodegasAsync = ref.watch(bodegasInventarioProvider);
    final estado = ref.watch(kardexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tarjeta de Existencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bodegasAsync.when(
              data: (bodegas) => DropdownButtonFormField<BodegaResumen>(
                key: const Key('kardexBodega'),
                value: _bodega,
                decoration: const InputDecoration(labelText: 'Bodega'),
                items: bodegas.map((b) => DropdownMenuItem(value: b, child: Text('${b.nombreBodega} (${b.nombreSucursal})'))).toList(),
                onChanged: (valor) => setState(() => _bodega = valor),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('No se pudieron cargar las Bodegas: $e'),
            ),
            const SizedBox(height: 12),
            if (_producto == null) ...[
              TextField(
                key: const Key('kardexBusquedaProducto'),
                controller: _busquedaController,
                decoration: InputDecoration(
                  labelText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscando
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : null,
                ),
                onChanged: _buscar,
              ),
              const SizedBox(height: 8),
              ..._resultados.map((producto) => ListTile(
                    key: Key('kardexResultado_${producto.varianteProductoId}'),
                    title: Text(producto.nombreProducto),
                    subtitle: Text(producto.sku),
                    onTap: () => setState(() => _producto = producto),
                  )),
            ] else
              ListTile(
                title: Text(_producto!.nombreProducto),
                subtitle: Text(_producto!.sku),
                trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _producto = null)),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('kardexConsultar'),
              icon: const Icon(Icons.search),
              label: const Text('Consultar'),
              onPressed: (_bodega == null || _producto == null)
                  ? null
                  : () => ref.read(kardexProvider.notifier).consultar(bodegaId: _bodega!.bodegaId, varianteProductoId: _producto!.varianteProductoId),
            ),
            const SizedBox(height: 16),
            if (estado.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Expanded(
              child: estado.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : !estado.consultado
                      ? const Center(child: Text('Elige Bodega y Producto, luego toca Consultar.'))
                      : estado.lineas.isEmpty
                          ? const Center(child: Text('Sin movimientos registrados'))
                          : ListView.separated(
                              itemCount: estado.lineas.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final linea = estado.lineas[index];
                                final esEntrada = linea.tipo == TipoMovimientoInventario.entrada;
                                return ListTile(
                                  key: Key('lineaKardex_$index'),
                                  leading: Icon(esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: esEntrada ? Colors.green : Theme.of(context).colorScheme.error),
                                  title: Text('${esEntrada ? 'Entrada' : 'Salida'}: ${_formatearCantidad(linea.cantidad)}'),
                                  subtitle: Text(
                                    '${linea.motivo ?? 'Sin motivo'} · ${linea.fechaMovimiento.toLocal().toString().split('.').first}',
                                  ),
                                  trailing: Text('Saldo: ${_formatearCantidad(linea.saldoAcumulado)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatearCantidad(double cantidad) =>
      cantidad.truncateToDouble() == cantidad ? cantidad.toInt().toString() : cantidad.toString();

  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);
    try {
      final resultados = await ref.read(catalogRepositoryProvider).buscarProductos(texto: texto);
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
}
