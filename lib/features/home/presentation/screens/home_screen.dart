import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cash/presentation/providers/cash_providers.dart';
import '../../../customers/presentation/providers/solicitudes_credito_pendientes_providers.dart';
import '../../../sales/presentation/providers/descuentos_pendientes_providers.dart';

/// Menú principal post-login — una grilla de tarjetas (`MenuCard`, ver
/// core/widgets/menu_card.dart), cada una con su propia etiqueta de
/// categoría (Ventas, Clientes, Compras, etc.), en vez de una lista
/// plana. El resto de las pantallas se agregan acá como nuevas tarjetas,
/// cada una con su propia carpeta bajo lib/features/ siguiendo el mismo
/// patrón que auth/ y sales/.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Refresca la cantidad de descuentos pendientes cada 20s mientras el
  /// Home está en pantalla — más espaciado que el poll de 3s del POS
  /// (ahí el Cajero está esperando activamente una respuesta; acá es solo
  /// un indicador pasivo en el menú). `cargar()` en el controller ya
  /// existe y no molesta si se llama sin tener el permiso, pero evitamos
  /// el llamado innecesario igual.
  Timer? _pollDescuentosPendientes;
  Timer? _pollSolicitudesCredito;
  Timer? _pollRetirosPendientes;

  @override
  void initState() {
    super.initState();
    _pollDescuentosPendientes = Timer.periodic(const Duration(seconds: 20), (_) {
      if (ref.read(authControllerProvider).sesion?.tienePermiso('sales.descuentos.autorizar') ?? false) {
        ref.read(descuentosPendientesProvider.notifier).cargar();
      }
    });
    _pollSolicitudesCredito = Timer.periodic(const Duration(seconds: 20), (_) {
      if (ref.read(authControllerProvider).sesion?.tienePermiso('customers.clientes.autorizarcredito') ?? false) {
        ref.read(solicitudesCreditoPendientesProvider.notifier).cargar();
      }
    });
    _pollRetirosPendientes = Timer.periodic(const Duration(seconds: 20), (_) {
      if (ref.read(authControllerProvider).sesion?.tienePermiso('cash.retiros.autorizar') ?? false) {
        ref.read(retirosPendientesProvider.notifier).cargar();
      }
    });
  }

  @override
  void dispose() {
    _pollDescuentosPendientes?.cancel();
    _pollSolicitudesCredito?.cancel();
    _pollRetirosPendientes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authControllerProvider).sesion;
    final tieneAutorizarDescuentos = sesion?.tienePermiso('sales.descuentos.autorizar') ?? false;
    final tieneClientes = sesion?.tienePermiso('customers.clientes.gestionar') ?? false;
    final tieneDevoluciones = sesion?.tienePermiso('sales.devoluciones.registrar') ?? false;
    final tieneCompras = (sesion?.tienePermiso('purchasing.ordenescompra.gestionar') ?? false) ||
        (sesion?.tienePermiso('purchasing.proveedores.gestionar') ?? false);
    final tieneOrdenesTrabajo = sesion?.tienePermiso('sales.ordenestrabajo.gestionar') ?? false;
    final tieneInventario = sesion?.tienePermiso('inventory.stock.ver') ?? false;
    final tieneReportes = sesion?.tienePermiso('reporting.reportes.ver') ?? false;
    // Solo se observa el provider si hay permiso — evita el llamado inicial
    // a listarDescuentosPendientes() para Usuarios que ni siquiera ven la
    // tarjeta (ej. un Cajero sin el permiso).
    final cantidadDescuentosPendientes =
        tieneAutorizarDescuentos ? ref.watch(descuentosPendientesProvider).pendientes.length : 0;
    final tieneAutorizarCredito = sesion?.tienePermiso('customers.clientes.autorizarcredito') ?? false;
    final cantidadSolicitudesCreditoPendientes =
        tieneAutorizarCredito ? ref.watch(solicitudesCreditoPendientesProvider).pendientes.length : 0;
    final tieneAutorizarRetiros = sesion?.tienePermiso('cash.retiros.autorizar') ?? false;
    final cantidadRetirosPendientes = tieneAutorizarRetiros ? ref.watch(retirosPendientesProvider).pendientes.length : 0;

    return MenuScaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: SvgPicture.asset('assets/branding/novapos_wordmark.svg', height: 68, alignment: Alignment.centerLeft),
        bottom: sesion == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      children: [
                        TextSpan(text: '${sesion.nombreCompleto} · '),
                        TextSpan(
                          text: sesion.empresaRazonSocial,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      tarjetas: [
        MenuCard(
          categoria: 'Ventas',
          titulo: 'Punto de Venta',
          subtitulo: 'Buscar productos, armar el carrito y cobrar.',
          onTap: () => context.push('/pos'),
        ),
        MenuCard(
          key: const Key('homeCotizacionesCard'),
          categoria: 'Ventas',
          titulo: 'Cotizaciones',
          subtitulo: 'Revisar, buscar y reimprimir las Cotizaciones guardadas.',
          onTap: () => context.push('/cotizaciones'),
        ),
        if (tieneAutorizarDescuentos)
          MenuCard(
            categoria: 'Ventas',
            titulo: 'Autorización de Descuento',
            subtitulo: 'Autorizar o rechazar descuentos solicitados en el POS.',
            badge: cantidadDescuentosPendientes > 0 ? cantidadDescuentosPendientes : null,
            badgeKey: const Key('badgeDescuentosPendientes'),
            onTap: () => context.push('/descuentos-pendientes'),
          ),
        if (tieneOrdenesTrabajo)
          MenuCard(
            key: const Key('homeOrdenesTrabajoCard'),
            categoria: 'Ventas',
            titulo: 'Órdenes de Trabajo',
            subtitulo: 'Reparaciones y servicios cobrables a un Cliente.',
            onTap: () => context.push('/ordenes-trabajo'),
          ),
        MenuCard(
          categoria: 'Catálogo',
          titulo: 'Productos',
          subtitulo: 'Productos, Marcas, Categorías y Ofertas y Promociones para Imprimir.',
          onTap: () => context.push('/catalogo'),
        ),
        if (tieneClientes)
          MenuCard(
            key: const Key('homeClientesCard'),
            categoria: 'Clientes, Cuentas x Cobrar',
            titulo: 'Clientes',
            subtitulo: 'Mantención, Cuentas x Cobrar y Plazos de Pago.',
            onTap: () => context.push('/clientes'),
          ),
        if (tieneDevoluciones)
          MenuCard(
            key: const Key('homeDevolucionVentaCard'),
            categoria: 'Atención de Clientes',
            titulo: 'Devolución de productos',
            subtitulo: 'Devolver productos de una Venta (Boleta o Factura).',
            onTap: () => context.push('/devolucion-venta'),
          ),
        if (tieneAutorizarCredito)
          MenuCard(
            key: const Key('homeCreditoPendienteCard'),
            categoria: 'Clientes',
            titulo: 'Autorización de Crédito',
            subtitulo: 'Autorizar o rechazar solicitudes de crédito de Clientes.',
            badge: cantidadSolicitudesCreditoPendientes > 0 ? cantidadSolicitudesCreditoPendientes : null,
            badgeKey: const Key('badgeCreditoPendiente'),
            onTap: () => context.push('/clientes/credito-pendientes'),
          ),
        if (tieneAutorizarRetiros)
          MenuCard(
            key: const Key('homeRetirosCajaCard'),
            categoria: 'Ventas',
            titulo: 'Autorización de Retiros de Caja',
            subtitulo: 'Autorizar o rechazar retiros de efectivo solicitados en el POS.',
            badge: cantidadRetirosPendientes > 0 ? cantidadRetirosPendientes : null,
            badgeKey: const Key('badgeRetirosCaja'),
            onTap: () => context.push('/caja/retiros-pendientes'),
          ),
        if (tieneCompras)
          MenuCard(
            key: const Key('homeComprasCard'),
            categoria: 'Proveedores, Cuentas x Pagar',
            titulo: 'Proveedores y Órdenes',
            subtitulo: 'Proveedores, Documentos Recibidos, Órdenes de Compra, Discrepancias, Cuentas por Pagar y Plazos de Pago.',
            onTap: () => context.push('/compras'),
          ),
        if (tieneInventario)
          MenuCard(
            key: const Key('homeInventarioCard'),
            categoria: 'Inventario',
            titulo: 'Stock en tiempo real',
            subtitulo: 'Ajustes, Traslados y Tarjeta de Existencia.',
            onTap: () => context.push('/inventario'),
          ),
        if (tieneReportes)
          MenuCard(
            key: const Key('homeFlujoCajaCard'),
            categoria: 'Reportes',
            titulo: 'Flujo de Caja',
            subtitulo: 'Ingresos y egresos por período.',
            onTap: () => context.push('/reportes/flujo-caja'),
          ),
      ],
    );
  }
}
