import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/clasificacion.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../tenancy/domain/models/caja_resumen.dart';
import '../../domain/models/resumen_venta.dart';
import '../providers/pos_providers.dart';
import '../widgets/carrito_linea_tile.dart';
import '../widgets/producto_resultado_tile.dart';
import '../widgets/selector_cliente_dialog.dart';
import 'escanear_codigo_barra_screen.dart';

/// Firma de la función que abre el escáner y devuelve el código detectado
/// (o null si se canceló) — inyectable para poder simular un escaneo en
/// tests sin tocar la cámara real (mismo criterio que SecureStorage).
typedef EscanearCodigoBarra = Future<String?> Function(BuildContext context);

Future<String?> _escanearCodigoBarraReal(BuildContext context) =>
    Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const EscanearCodigoBarraScreen()));

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key, this.escanearCodigoBarra = _escanearCodigoBarraReal, this.escaneoDisponible});

  final EscanearCodigoBarra escanearCodigoBarra;

  /// Null = detectar según la plataforma real (mobile_scanner no tiene
  /// implementación para Windows desktop, donde un lector físico de
  /// código de barras ya funciona como teclado sobre el buscador). Se
  /// puede forzar explícito en tests, donde `Platform.isWindows` refleja
  /// el equipo que corre el test, no la plataforma que se quiere simular.
  final bool? escaneoDisponible;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    final departamentoId = ref.read(departamentoSeleccionadoProvider);
    final bodegaId = ref.read(bodegaVentaProvider).valueOrNull?.bodegaId;
    ref.read(busquedaProductosProvider.notifier).buscar(texto, departamentoId: departamentoId, bodegaId: bodegaId);
  }

  @override
  Widget build(BuildContext context) {
    final cajasAsync = ref.watch(cajasProvider);
    final cajaSeleccionada = ref.watch(cajaSeleccionadaProvider);
    final busqueda = ref.watch(busquedaProductosProvider);
    final carrito = ref.watch(posCartProvider);
    final departamentosAsync = ref.watch(departamentosProvider);
    final departamentoSeleccionado = ref.watch(departamentoSeleccionadoProvider);
    final clienteSeleccionado = ref.watch(clienteSeleccionadoProvider);

    ref.listen(cajasProvider, (previo, actual) {
      actual.whenData((cajas) {
        if (cajaSeleccionada == null && cajas.length == 1) {
          ref.read(cajaSeleccionadaProvider.notifier).state = cajas.first;
        }
      });
    });

    // La Bodega de venta se resuelve async apenas se elige/auto-selecciona
    // la Caja — si la búsqueda inicial ya corrió sin Bodega, se repite acá
    // para agregar el stock que faltaba la primera vez.
    ref.listen(bodegaVentaProvider, (previo, actual) {
      actual.whenData((bodega) {
        if (bodega != null && previo?.valueOrNull == null) {
          _buscar(_busquedaController.text);
        }
      });
    });

    ref.listen(posCartProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      if (actual.resumenCobrado != null && previo?.resumenCobrado == null) {
        _mostrarVentaCobrada(actual.resumenCobrado!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        actions: [
          cajasAsync.when(
            data: (cajas) => cajas.length <= 1
                ? const SizedBox.shrink()
                : _SelectorCaja(cajas: cajas, seleccionada: cajaSeleccionada),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cajasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar la Caja: $error')),
        data: (cajas) {
          if (cajas.isEmpty) {
            return const Center(child: Text('Esta Empresa no tiene ninguna Caja configurada.'));
          }
          if (cajaSeleccionada == null) {
            return const Center(child: Text('Elige con qué Caja vas a trabajar.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ListTile(
                  key: const Key('posCliente'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(clienteSeleccionado?.nombre ?? 'Cliente Genérico'),
                  subtitle: clienteSeleccionado?.rut != null ? Text(clienteSeleccionado!.rut!) : null,
                  trailing: const Text('Cambiar'),
                  onTap: () => _elegirCliente(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const Key('posBusqueda'),
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto (nombre, SKU o código de barras)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (busqueda.buscando)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        if (widget.escaneoDisponible ?? (kIsWeb || !Platform.isWindows))
                          IconButton(
                            key: const Key('posEscanear'),
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Escanear código de barras',
                            onPressed: () => _escanear(context),
                          ),
                      ],
                    ),
                  ),
                  onChanged: _buscar,
                ),
              ),
              departamentosAsync.when(
                data: (departamentos) => departamentos.isEmpty
                    ? const SizedBox.shrink()
                    : _TabsCategorias(
                        departamentos: departamentos,
                        seleccionado: departamentoSeleccionado,
                        onSeleccionar: (departamentoId) {
                          ref.read(departamentoSeleccionadoProvider.notifier).state = departamentoId;
                          _buscar(_busquedaController.text);
                        },
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Expanded(
                flex: 3,
                child: busqueda.resultados.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView.builder(
                        itemCount: busqueda.resultados.length,
                        itemBuilder: (context, index) {
                          final producto = busqueda.resultados[index];
                          return ProductoResultadoTile(
                            key: Key('posResultado_${producto.varianteProductoId}'),
                            producto: producto,
                            stock: busqueda.stock[producto.varianteProductoId],
                            onAgregar: () => ref.read(posCartProvider.notifier).agregarProducto(producto),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Expanded(
                flex: 2,
                child: carrito.lineas.isEmpty
                    ? const Center(child: Text('Carrito vacío'))
                    : ListView.builder(
                        itemCount: carrito.lineas.length,
                        itemBuilder: (context, index) {
                          final linea = carrito.lineas[index];
                          return CarritoLineaTile(
                            key: Key('posCarrito_${linea.producto.varianteProductoId}'),
                            linea: linea,
                            onCambiarCantidad: (cantidad) => ref
                                .read(posCartProvider.notifier)
                                .cambiarCantidad(linea.producto.varianteProductoId, cantidad),
                            onQuitar: () =>
                                ref.read(posCartProvider.notifier).quitarLinea(linea.producto.varianteProductoId),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Neto: ${MonedaFormatter.formatear(carrito.resumen.neto)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'IVA (19%): ${MonedaFormatter.formatear(carrito.resumen.iva)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Total: ${MonedaFormatter.formatear(carrito.total)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        key: const Key('posCobrar'),
                        onPressed: (carrito.lineas.isEmpty || carrito.cobrando)
                            ? null
                            : () => ref.read(posCartProvider.notifier).cobrar(
                                  cajaId: cajaSeleccionada.cajaId,
                                  clienteId: ref.read(clienteSeleccionadoProvider)?.id,
                                ),
                        child: carrito.cobrando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Cobrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Abre el escáner y, si detecta un código, busca ese código exacto y
  /// agrega el producto directo al carrito — a diferencia de tipear en el
  /// buscador, un código escaneado no necesita que el Cajero elija entre
  /// resultados: si hay una coincidencia exacta de CódigoBarras, se agrega sola.
  Future<void> _escanear(BuildContext context) async {
    final codigo = await widget.escanearCodigoBarra(context);
    if (codigo == null || !mounted) return;
    await _buscarPorCodigoYAgregar(codigo);
  }

  Future<void> _buscarPorCodigoYAgregar(String codigo) async {
    _busquedaController.text = codigo;
    final departamentoId = ref.read(departamentoSeleccionadoProvider);
    final bodegaId = ref.read(bodegaVentaProvider).valueOrNull?.bodegaId;
    await ref
        .read(busquedaProductosProvider.notifier)
        .buscarInmediato(codigo, departamentoId: departamentoId, bodegaId: bodegaId);
    if (!mounted) return;

    final encontrado = ref.read(busquedaProductosProvider).resultados.where((p) => p.codigoBarras == codigo);
    if (encontrado.isNotEmpty) {
      ref.read(posCartProvider.notifier).agregarProducto(encontrado.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró ningún producto con el código $codigo')),
      );
    }
  }

  Future<void> _elegirCliente(BuildContext context) async {
    // El diálogo solo se cierra con una acción explícita (elegir un
    // Cliente, "Usar Cliente Genérico", o "Cancelar") — las tres devuelven
    // ClienteResumen? (null = Genérico), así que "Cancelar" también deja
    // el Cliente Genérico seleccionado en vez de mantener el anterior.
    // Simplifica el estado a propósito: no hay un tercer valor "no cambiar".
    final elegido = await showDialog<ClienteResumen?>(
      context: context,
      builder: (_) => const SelectorClienteDialog(),
    );
    ref.read(clienteSeleccionadoProvider.notifier).state = elegido;
  }

  void _mostrarVentaCobrada(ResumenVenta resumen) {
    ref.read(clienteSeleccionadoProvider.notifier).state = null;
    _busquedaController.clear();
    _buscar('');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Venta confirmada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neto: ${MonedaFormatter.formatear(resumen.neto)}'),
            Text('IVA (19%): ${MonedaFormatter.formatear(resumen.iva)}'),
            Text('Total cobrado: ${MonedaFormatter.formatear(resumen.total)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(posCartProvider.notifier).limpiarVentaCobrada();
            },
            child: const Text('Nueva Venta'),
          ),
        ],
      ),
    );
  }
}

class _TabsCategorias extends StatelessWidget {
  const _TabsCategorias({required this.departamentos, required this.seleccionado, required this.onSeleccionar});

  final List<Departamento> departamentos;
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              key: const Key('posCategoriaTodos'),
              label: const Text('Todos'),
              selected: seleccionado == null,
              onSelected: (_) => onSeleccionar(null),
            ),
          ),
          for (final departamento in departamentos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                key: Key('posCategoria_${departamento.id}'),
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

class _SelectorCaja extends ConsumerWidget {
  const _SelectorCaja({required this.cajas, required this.seleccionada});

  final List<CajaResumen> cajas;
  final CajaResumen? seleccionada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<CajaResumen>(
      value: seleccionada,
      hint: const Text('Elige una Caja', style: TextStyle(color: Colors.white)),
      dropdownColor: Theme.of(context).colorScheme.primary,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: Colors.white),
      items: cajas
          .map((caja) => DropdownMenuItem(value: caja, child: Text('${caja.nombreCaja} (${caja.nombreSucursal})')))
          .toList(),
      onChanged: (caja) => ref.read(cajaSeleccionadaProvider.notifier).state = caja,
    );
  }
}
