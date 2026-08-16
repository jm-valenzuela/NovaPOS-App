import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../catalog/domain/models/clasificacion.dart';
import '../../../cash/presentation/providers/cash_providers.dart';
import '../../../cash/presentation/widgets/abrir_caja_dialog.dart';
import '../../../cash/presentation/widgets/arqueo_caja_dialog.dart';
import '../../../cash/presentation/widgets/retirar_efectivo_dialog.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../returns/domain/models/nota_credito_disponible_resumen.dart';
import '../../../returns/presentation/widgets/elegir_nota_credito_devolucion_dialog.dart';
import '../../../tenancy/domain/models/caja_resumen.dart';
import '../../../catalog/domain/models/producto_vendible.dart';
import '../../domain/models/cotizacion.dart';
import '../../domain/models/linea_carrito.dart';
import '../../domain/models/resumen_venta.dart';
import '../../domain/models/venta_enums.dart';
import '../providers/pos_providers.dart';
import '../theme/pos_colors.dart';
import '../widgets/cantidad_pesable_dialog.dart';
import '../widgets/carrito_linea_tile.dart';
import '../widgets/checkout_dialog.dart';
import '../widgets/producto_resultado_tile.dart';
import '../widgets/representacion_impresa_venta.dart';
import '../widgets/rescatar_cotizacion_dialog.dart';
import '../widgets/selector_cliente_dialog.dart';
import '../widgets/solicitar_descuento_dialog.dart';
import '../widgets/ticket_cotizacion.dart';
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

  /// Mientras haya un descuento Pendiente, consulta cada 3s si ya lo
  /// resolvieron — sirve igual si el Supervisor está en el piso (lo
  /// resuelve casi al toque) o en la oficina (tarda más). El método del
  /// controller no hace nada si no hay nada pendiente, así que no hace
  /// falta prender/apagar el timer según el estado.
  Timer? _pollDescuento;

  @override
  void initState() {
    super.initState();
    _pollDescuento = Timer.periodic(
      const Duration(seconds: 3),
      (_) => ref.read(posCartProvider.notifier).verificarEstadoDescuento(),
    );
  }

  @override
  void dispose() {
    _pollDescuento?.cancel();
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
        _mostrarVentaCobrada(actual.resumenCobrado!, actual.vueltoCobrado, actual.lineasCobradas);
      }
      // Solo avisa si la resolución ocurrió en vivo (Pendiente → Autorizado/
      // Rechazado, ver verificarEstadoDescuento) — al rescatar una Cotización
      // que ya traía un descuento resuelto de antes, el estado también
      // "cambia" (de sinSolicitar a Autorizado, por ejemplo), pero no es un
      // evento que acabe de pasar, así que no corresponde el mismo aviso
      // (bug real, reportado por el usuario: "la muestra como que en ese
      // momento fue aprobada").
      if (previo?.estadoDescuento == EstadoDescuentoGeneral.pendiente &&
          actual.estadoDescuento != previo?.estadoDescuento) {
        if (actual.estadoDescuento == EstadoDescuentoGeneral.autorizado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descuento autorizado — ya puedes cobrar.'), backgroundColor: Colors.green),
          );
        } else if (actual.estadoDescuento == EstadoDescuentoGeneral.rechazado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Descuento rechazado: ${actual.motivoRechazoDescuento ?? "sin motivo"}')),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: PosColors.workspace,
      appBar: AppBar(
        backgroundColor: PosColors.navy,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            // El ícono es un cuadrado navy — sin este fondo claro detrás,
            // se pierde contra el AppBar (también navy) y queda "flotando".
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFEFEBE1), borderRadius: BorderRadius.circular(8)),
              child: SvgPicture.asset('assets/branding/novapos_icon.svg', width: 22, height: 22),
            ),
            const SizedBox(width: 10),
            const Text('NovaPOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (cajaSeleccionada != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${cajaSeleccionada.nombreSucursal} · ${cajaSeleccionada.nombreCaja}',
                  style: const TextStyle(color: PosColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          if (cajaSeleccionada != null)
            _AccionesCaja(
              cajaId: cajaSeleccionada.cajaId,
              nombreCaja: cajaSeleccionada.nombreCaja,
            ),
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

          final sesionCaja = ref.watch(sesionCajaProvider(cajaSeleccionada.cajaId));
          if (sesionCaja.cargando && sesionCaja.sesion == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sesionCaja.sesion == null) {
            // Mientras la Caja no tenga una Sesión Abierta, no se deja
            // vender ni hacer ninguna otra interacción — a pedido explícito
            // del usuario ("mientras la caja no esté abierta no permita
            // realizar otra interacción").
            return _CajaCerradaPlaceholder(cajaId: cajaSeleccionada.cajaId, nombreCaja: cajaSeleccionada.nombreCaja);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('posBusqueda'),
                              controller: _busquedaController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Buscar producto por nombre, SKU o código de barras...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: busqueda.buscando
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: PosColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: PosColors.navy),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: _buscar,
                            ),
                          ),
                          if (widget.escaneoDisponible ?? (kIsWeb || !Platform.isWindows)) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              key: const Key('posEscanear'),
                              onPressed: () => _escanear(context),
                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                              label: const Text('Escanear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PosColors.navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
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
                      child: busqueda.resultados.isEmpty
                          ? const Center(child: Text('Sin resultados', style: TextStyle(color: PosColors.textMuted)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                // Suficiente para el peor caso real: badge de stock +
                                // nombre de 2 líneas + SKU + precio tachado + precio
                                // de oferta + etiqueta "Oferta", todo en la misma
                                // tarjeta (172 se quedaba corto por 3px en ese caso).
                                mainAxisExtent: 182,
                              ),
                              itemCount: busqueda.resultados.length,
                              itemBuilder: (context, index) {
                                final producto = busqueda.resultados[index];
                                return ProductoResultadoTile(
                                  key: Key('posResultado_${producto.varianteProductoId}'),
                                  producto: producto,
                                  stock: busqueda.stock[producto.varianteProductoId],
                                  onAgregar: () => _agregarProducto(context, producto),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              _PanelCarrito(
                carrito: carrito,
                clienteSeleccionado: clienteSeleccionado,
                stockPorVariante: busqueda.stock,
                onElegirCliente: () => _elegirCliente(context),
                onCobrar: () => _cobrar(context, cajaSeleccionada.cajaId, carrito.totalConDescuento),
                onVaciar: () => _vaciar(context, ref, carrito),
                onSolicitarDescuento: () => _solicitarDescuento(context, cajaSeleccionada.cajaId),
                onGuardarCotizacion: () => _guardarCotizacion(context, cajaSeleccionada.cajaId),
                onRescatarCotizacion: () => _rescatarCotizacion(context, cajaSeleccionada.sucursalId),
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
      await _agregarProducto(context, encontrado.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró ningún producto con el código $codigo')),
      );
    }
  }

  /// Por Unidad se agrega directo (un tap = una pieza más). Por Kilogramo
  /// o Litro, primero hay que preguntarle al Cajero el peso/volumen
  /// exacto — no tiene sentido "agregar 1" y ajustar de a 1 en 1 cuando
  /// la unidad real es una fracción de kilo.
  Future<void> _agregarProducto(BuildContext context, ProductoVendible producto) async {
    if (!producto.unidad.esPesable) {
      ref.read(posCartProvider.notifier).agregarProducto(producto);
      return;
    }
    final cantidad = await showDialog<double>(
      context: context,
      builder: (_) => CantidadPesableDialog(producto: producto),
    );
    if (cantidad == null || !mounted) return;
    ref.read(posCartProvider.notifier).agregarProducto(producto, cantidad: cantidad);
  }

  /// Abre CheckoutDialog para que el Cajero elija Boleta/Factura y (si es
  /// al Contado, único camino hoy — ver PosCartController.cobrar) el medio
  /// de pago, antes de confirmar la Venta.
  Future<void> _cobrar(BuildContext context, String cajaId, double total) async {
    final resultado = await showDialog<ResultadoCheckout>(
      context: context,
      builder: (_) => CheckoutDialog(
        total: total,
        formaPago: FormaPago.contado,
        clienteSeleccionado: ref.read(clienteSeleccionadoProvider),
      ),
    );
    if (resultado == null || !mounted) return;
    await ref.read(posCartProvider.notifier).cobrar(
          cajaId: cajaId,
          clienteId: ref.read(clienteSeleccionadoProvider)?.id,
          tipoDocumento: resultado.tipoDocumento,
          pagos: resultado.pagos,
          vuelto: resultado.vuelto,
        );
  }

  Future<void> _solicitarDescuento(BuildContext context, String cajaId) async {
    final solicitado = await showDialog<DescuentoSolicitado>(
      context: context,
      builder: (_) => const SolicitarDescuentoDialog(),
    );
    if (solicitado == null || !mounted) return;
    await ref.read(posCartProvider.notifier).solicitarDescuento(
          cajaId: cajaId,
          clienteId: ref.read(clienteSeleccionadoProvider)?.id,
          porcentaje: solicitado.porcentaje,
          monto: solicitado.monto,
        );
  }

  /// Guarda el carrito actual como Cotización e imprime el ticket. A
  /// diferencia de antes, vuelve a consultar el detalle recién guardado
  /// (en vez de reconstruirlo con lo que ya estaba en pantalla) porque el
  /// backend recién ahí le asigna el NumeroCotizacion — el ticket necesita
  /// ese número real, no algo estimado en el cliente. Limpia Cliente y
  /// búsqueda igual que tras un cobro, para no arrastrarlos a la siguiente venta.
  Future<void> _guardarCotizacion(BuildContext context, String cajaId) async {
    final cliente = ref.read(clienteSeleccionadoProvider);

    final ventaId = await ref.read(posCartProvider.notifier).guardarCotizacion(
          cajaId: cajaId,
          clienteId: cliente?.id,
        );
    if (ventaId == null || !mounted) return;

    ref.read(clienteSeleccionadoProvider.notifier).state = null;
    _busquedaController.clear();
    _buscar('');

    final detalle = await ref.read(salesRepositoryProvider).obtenerCotizacion(ventaId);
    await imprimirTicketCotizacion(detalle);
  }

  /// Rescata una Cotización guardada — si el carrito actual ya tiene
  /// productos, pide confirmación antes de reemplazarlo (mismo criterio
  /// que _vaciar: no descarta trabajo en curso en silencio).
  Future<void> _rescatarCotizacion(BuildContext context, String sucursalId) async {
    final elegida = await showDialog<CotizacionResumen>(
      context: context,
      builder: (_) => RescatarCotizacionDialog(sucursalId: sucursalId),
    );
    if (elegida == null || !mounted) return;

    if (ref.read(posCartProvider).lineas.isNotEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Reemplazar el carrito actual?'),
          content: const Text(
            'Ya tienes productos en el carrito. Rescatar esta Cotización descarta lo que llevas armado.',
          ),
          actions: [
            TextButton(
              key: const Key('confirmarRescatarCancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirmarRescatarConfirmar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    final detalle = await ref.read(posCartProvider.notifier).rescatarCotizacion(elegida.ventaId);
    if (detalle == null || !mounted) return;

    ref.read(clienteSeleccionadoProvider.notifier).state = ClienteResumen(
      id: detalle.clienteId,
      rut: detalle.clienteRut,
      nombre: detalle.clienteNombre,
      email: null,
      telefono: null,
    );
  }

  /// Si ya se pidió un descuento para esta venta (Pendiente, Autorizado o
  /// Rechazado), vaciar abandona la Venta que ya existe en el servidor —
  /// se avisa antes en vez de borrarlo en silencio.
  Future<void> _vaciar(BuildContext context, WidgetRef ref, PosCartState carrito) async {
    if (carrito.estadoDescuento != EstadoDescuentoGeneral.sinSolicitar) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Vaciar el carrito?'),
          content: const Text(
            'Ya se solicitó un descuento para esta venta. Vaciar el carrito lo descarta — '
            'tendrás que pedirlo de nuevo si sigues con esta venta.',
          ),
          actions: [
            TextButton(
              key: const Key('confirmarVaciarCancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirmarVaciarConfirmar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Vaciar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    ref.read(posCartProvider.notifier).vaciarCarrito();
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

  void _mostrarVentaCobrada(ResumenVenta resumen, double vuelto, List<LineaCarrito> lineas) {
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
            Text('Subtotal: ${MonedaFormatter.formatear(resumen.neto)}'),
            Text('IVA (19%): ${MonedaFormatter.formatear(resumen.iva)}'),
            Text('Total cobrado: ${MonedaFormatter.formatear(resumen.total)}'),
            if (vuelto > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Vuelto: ${MonedaFormatter.formatear(vuelto)}',
                key: const Key('ventaConfirmadaVuelto'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
            if (resumen.tieneDte) ...[
              const SizedBox(height: 4),
              Text('Folio ${resumen.folio}', style: const TextStyle(color: Colors.black54)),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'No se pudo emitir el documento tributario de esta Venta.',
                key: Key('ventaConfirmadaSinDte'),
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          if (resumen.tieneDte)
            TextButton(
              key: const Key('ventaConfirmadaImprimir'),
              onPressed: () => imprimirBoletaFactura(resumen, lineas),
              child: const Text('Imprimir'),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ChipCategoria(
              key: const Key('posCategoriaTodos'),
              label: 'Todos',
              selected: seleccionado == null,
              onTap: () => onSeleccionar(null),
            ),
          ),
          for (final departamento in departamentos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ChipCategoria(
                key: Key('posCategoria_${departamento.id}'),
                label: departamento.nombre,
                selected: seleccionado == departamento.id,
                onTap: () => onSeleccionar(departamento.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PosColors.navy,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? PosColors.navy : PosColors.cardBorder),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
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
      dropdownColor: PosColors.navy,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: Colors.white),
      items: cajas
          .map((caja) => DropdownMenuItem(value: caja, child: Text('${caja.nombreCaja} (${caja.nombreSucursal})')))
          .toList(),
      onChanged: (caja) => ref.read(cajaSeleccionadaProvider.notifier).state = caja,
    );
  }
}

/// Abre el diálogo de Apertura de Caja y, si se confirma, llama al
/// controller — compartido entre el ícono del AppBar y el placeholder que
/// bloquea el POS mientras no hay Sesión Abierta. Cancelar el diálogo no
/// hace nada (el usuario queda igual bloqueado, puede reintentar cuando
/// quiera desde cualquiera de los dos puntos de entrada).
Future<void> _abrirCaja(BuildContext context, WidgetRef ref, String cajaId, String nombreCaja) async {
  final monto = await showDialog<double>(
    context: context,
    builder: (_) => AbrirCajaDialog(nombreCaja: nombreCaja),
  );
  if (monto != null) await ref.read(sesionCajaProvider(cajaId).notifier).abrir(monto);
}

/// Reemplaza todo el cuerpo del POS mientras la Caja seleccionada no tiene
/// una Sesión Abierta — a pedido explícito del usuario ("mientras la caja
/// no esté abierta no permita realizar otra interacción"), ni buscar ni
/// cobrar quedan alcanzables hasta declarar el efectivo inicial.
class _CajaCerradaPlaceholder extends ConsumerWidget {
  const _CajaCerradaPlaceholder({required this.cajaId, required this.nombreCaja});

  final String cajaId;
  final String nombreCaja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: PosColors.textMuted),
          const SizedBox(height: 16),
          Text('$nombreCaja está cerrada', style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Declara el efectivo inicial para empezar a vender.', style: TextStyle(color: PosColors.textMuted)),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('posCajaCerradaAbrir'),
            icon: const Icon(Icons.lock_open),
            label: const Text('Abrir Caja'),
            onPressed: () => _abrirCaja(context, ref, cajaId, nombreCaja),
          ),
        ],
      ),
    );
  }
}

/// Acciones de Caja en el AppBar — si no hay Sesión Abierta, ofrece
/// abrirla (ver AbrirCajaDialog, mismo diálogo que el placeholder que
/// bloquea el cuerpo del POS); si la hay, ofrece Retirar efectivo o
/// Cerrar Caja.
class _AccionesCaja extends ConsumerWidget {
  const _AccionesCaja({required this.cajaId, required this.nombreCaja});

  final String cajaId;
  final String nombreCaja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sesionCajaProvider(cajaId));
    final controller = ref.read(sesionCajaProvider(cajaId).notifier);

    if (estado.cargando && estado.sesion == null) return const SizedBox.shrink();

    if (estado.sesion == null) {
      return IconButton(
        key: const Key('posAbrirCaja'),
        tooltip: 'Abrir Caja',
        icon: const Icon(Icons.lock_outline, color: Colors.white),
        onPressed: () => _abrirCaja(context, ref, cajaId, nombreCaja),
      );
    }

    final sesion = estado.sesion!;
    return PopupMenuButton<String>(
      key: const Key('posMenuCaja'),
      icon: const Icon(Icons.point_of_sale, color: Colors.white),
      tooltip: 'Caja',
      onSelected: (valor) async {
        if (valor == 'retirar') {
          final resultado = await showDialog<({double monto, String motivo})>(
            context: context,
            builder: (_) => const RetirarEfectivoDialog(),
          );
          if (resultado != null) {
            final exito = await controller.solicitarRetiro(monto: resultado.monto, motivo: resultado.motivo);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(exito
                    ? 'Retiro solicitado — queda pendiente de autorización.'
                    : 'No se pudo solicitar el retiro.'),
              ));
            }
          }
        } else if (valor == 'arqueo') {
          showDialog<void>(
            context: context,
            builder: (_) => ArqueoCajaDialog(sesionCajaId: sesion.id),
          );
        } else if (valor == 'devolucion') {
          final notaReembolsada = await showDialog<NotaCreditoDisponibleResumen>(
            context: context,
            builder: (_) => ElegirNotaCreditoDevolucionDialog(sesionCajaId: sesion.id),
          );
          if (notaReembolsada != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${MonedaFormatter.formatear(notaReembolsada.montoTotal)} reembolsados en efectivo a ${notaReembolsada.clienteNombre}.'),
            ));
          }
        } else if (valor == 'cerrar') {
          context.push('/caja/cierre/${sesion.id}');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'retirar', child: Text('Retirar efectivo')),
        PopupMenuItem(value: 'arqueo', child: Text('Ver Arqueo')),
        PopupMenuItem(value: 'devolucion', child: Text('Registrar devolución por nota de crédito')),
        PopupMenuItem(value: 'cerrar', child: Text('Cerrar Caja')),
      ],
    );
  }
}

/// Panel fijo del carrito — Cliente, líneas, aviso de stock si corresponde,
/// desglose Subtotal/IVA/Total, y las acciones de cobro.
Future<void> _editarCantidad(BuildContext context, WidgetRef ref, LineaCarrito linea) async {
  final cantidad = await showDialog<double>(
    context: context,
    builder: (_) => CantidadPesableDialog(producto: linea.producto, cantidadInicial: linea.cantidad),
  );
  if (cantidad == null) return;
  ref.read(posCartProvider.notifier).cambiarCantidad(linea.producto.varianteProductoId, cantidad);
}

enum _AccionCotizacion { guardar, rescatar }

class _PanelCarrito extends ConsumerWidget {
  const _PanelCarrito({
    required this.carrito,
    required this.clienteSeleccionado,
    required this.stockPorVariante,
    required this.onElegirCliente,
    required this.onCobrar,
    required this.onVaciar,
    required this.onSolicitarDescuento,
    required this.onGuardarCotizacion,
    required this.onRescatarCotizacion,
  });

  final PosCartState carrito;
  final ClienteResumen? clienteSeleccionado;
  final Map<String, double> stockPorVariante;
  final VoidCallback onElegirCliente;
  final VoidCallback onCobrar;
  final VoidCallback onVaciar;
  final VoidCallback onSolicitarDescuento;
  final VoidCallback onGuardarCotizacion;
  final VoidCallback onRescatarCotizacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aviso informativo (nunca bloquea la venta) — solo detecta líneas cuyo
    // stock consultado en la búsqueda actual es exactamente 0. Si el
    // producto no aparece en el mapa (búsqueda distinta desde que se
    // agregó), simplemente no se muestra aviso para esa línea.
    final sinStock = carrito.lineas.where((l) => stockPorVariante[l.producto.varianteProductoId] == 0).toList();

    return Container(
      width: 400,
      color: PosColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: InkWell(
                key: const Key('posCliente'),
                onTap: onElegirCliente,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CLIENTE',
                              style: TextStyle(color: PosColors.textMuted, fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            clienteSeleccionado?.nombre ?? 'Cliente Genérico',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (clienteSeleccionado?.rut != null)
                            Text(clienteSeleccionado!.rut!, style: const TextStyle(color: PosColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Text('Cambiar', style: TextStyle(color: PosColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (carrito.numeroCotizacion != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  key: const Key('posNumeroCotizacionRescatada'),
                  children: [
                    const Icon(Icons.description_outlined, color: PosColors.accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cotización rescatada: ${carrito.numeroCotizacion}',
                        style: const TextStyle(color: PosColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            if (sinStock.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PosColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PosColors.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: PosColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${sinStock.map((l) => l.producto.nombreProducto).join(", ")} sin stock — se permitirá la venta',
                          style: const TextStyle(color: PosColors.accent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (carrito.estadoDescuento != EstadoDescuentoGeneral.sinSolicitar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _BannerDescuento(carrito: carrito),
              ),
            const Divider(color: PosColors.navyBorder, height: 24),
            Expanded(
              child: carrito.lineas.isEmpty
                  ? const Center(child: Text('Carrito vacío', style: TextStyle(color: PosColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: carrito.lineas.length,
                      separatorBuilder: (_, __) => const Divider(color: PosColors.navyBorder, height: 1),
                      itemBuilder: (context, index) {
                        final linea = carrito.lineas[index];
                        return CarritoLineaTile(
                          key: Key('posCarrito_${linea.producto.varianteProductoId}'),
                          linea: linea,
                          bloqueado: carrito.carritoBloqueado,
                          onCambiarCantidad: (cantidad) => ref
                              .read(posCartProvider.notifier)
                              .cambiarCantidad(linea.producto.varianteProductoId, cantidad),
                          onQuitar: () =>
                              ref.read(posCartProvider.notifier).quitarLinea(linea.producto.varianteProductoId),
                          onEditarCantidad: () => _editarCantidad(context, ref, linea),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: PosColors.navyBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (carrito.montoDescuentoAplicado > 0) _FilaDescuentoAplicado(carrito: carrito),
                  _FilaResumen(valorKey: const Key('posSubtotal'), label: 'Subtotal', valor: carrito.resumen.neto),
                  _FilaResumen(valorKey: const Key('posIva'), label: 'IVA (19%)', valor: carrito.resumen.iva),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(
                        MonedaFormatter.formatear(carrito.totalConDescuento),
                        key: const Key('posTotal'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('posCobrar'),
                    onPressed: (carrito.lineas.isEmpty ||
                            carrito.cobrando ||
                            carrito.estadoDescuento == EstadoDescuentoGeneral.pendiente)
                        ? null
                        : onCobrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PosColors.accent,
                      foregroundColor: PosColors.navy,
                      disabledBackgroundColor: PosColors.navyBorder,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    child: carrito.cobrando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Cobrar ${MonedaFormatter.formatear(carrito.totalConDescuento)}'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('posDescuento'),
                          onPressed: carrito.puedeSolicitarDescuento ? onSolicitarDescuento : null,
                          style: _estiloBotonSecundario,
                          child: carrito.solicitandoDescuento
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('+ Descuento', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PopupMenuButton<_AccionCotizacion>(
                          key: const Key('posCotizacion'),
                          enabled: !carrito.procesandoCotizacion,
                          onSelected: (accion) => switch (accion) {
                            _AccionCotizacion.guardar => onGuardarCotizacion(),
                            _AccionCotizacion.rescatar => onRescatarCotizacion(),
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              key: const Key('cotizacionGuardarItem'),
                              value: _AccionCotizacion.guardar,
                              enabled: carrito.lineas.isNotEmpty,
                              child: const Text('Guardar cotización'),
                            ),
                            const PopupMenuItem(
                              key: Key('cotizacionRescatarItem'),
                              value: _AccionCotizacion.rescatar,
                              child: Text('Rescatar cotización'),
                            ),
                          ],
                          child: IgnorePointer(
                            child: OutlinedButton(
                              onPressed: null,
                              style: _estiloBotonSecundario,
                              child: carrito.procesandoCotizacion
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Cotización', overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: carrito.lineas.isEmpty ? null : onVaciar,
                          style: _estiloBotonSecundario,
                          child: const Text('Vaciar', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _estiloBotonSecundario => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: PosColors.textMuted,
        side: const BorderSide(color: PosColors.navyBorder),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
}

class _BannerDescuento extends StatelessWidget {
  const _BannerDescuento({required this.carrito});

  final PosCartState carrito;

  String get _etiquetaValor => carrito.descuentoPorcentaje != null
      ? '${_formatearNumero(carrito.descuentoPorcentaje!)}%'
      : MonedaFormatter.formatear(carrito.descuentoMonto ?? 0);

  static String _formatearNumero(double n) => n.truncateToDouble() == n ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    final (color, icono, mensaje) = switch (carrito.estadoDescuento) {
      EstadoDescuentoGeneral.pendiente => (
          PosColors.accent,
          Icons.hourglass_top,
          'Descuento de $_etiquetaValor pendiente de autorización...',
        ),
      EstadoDescuentoGeneral.autorizado => (
          PosColors.stockOk,
          Icons.check_circle,
          'Descuento de $_etiquetaValor autorizado.',
        ),
      EstadoDescuentoGeneral.rechazado => (
          PosColors.stockOut,
          Icons.cancel,
          'Descuento rechazado: ${carrito.motivoRechazoDescuento ?? "sin motivo"}',
        ),
      EstadoDescuentoGeneral.sinSolicitar => (PosColors.textMuted, Icons.info_outline, ''),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// El monto que restó el descuento autorizado — antes solo se veía el
/// efecto en el Total (y por lo tanto en el Subtotal/IVA, que se derivan
/// de él), sin ningún $ explícito que explicara la diferencia.
class _FilaDescuentoAplicado extends StatelessWidget {
  const _FilaDescuentoAplicado({required this.carrito});

  final PosCartState carrito;

  String get _etiqueta => carrito.descuentoPorcentaje != null
      ? 'Descuento (${_formatearNumero(carrito.descuentoPorcentaje!)}%)'
      : 'Descuento';

  static String _formatearNumero(double n) => n.truncateToDouble() == n ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_etiqueta, style: const TextStyle(color: PosColors.accent)),
          Text(
            '-${MonedaFormatter.formatear(carrito.montoDescuentoAplicado)}',
            key: const Key('posDescuentoAplicado'),
            style: const TextStyle(color: PosColors.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({required this.label, required this.valor, this.valorKey});

  final String label;
  final double valor;
  final Key? valorKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: PosColors.textMuted)),
          Text(MonedaFormatter.formatear(valor), key: valorKey, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
