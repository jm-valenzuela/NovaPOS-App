import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
  }

  @override
  void dispose() {
    _pollDescuentosPendientes?.cancel();
    _pollSolicitudesCredito?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authControllerProvider).sesion;
    final tieneAutorizarDescuentos = sesion?.tienePermiso('sales.descuentos.autorizar') ?? false;
    final tieneClientes = sesion?.tienePermiso('customers.clientes.gestionar') ?? false;
    final tieneCompras = (sesion?.tienePermiso('purchasing.ordenescompra.gestionar') ?? false) ||
        (sesion?.tienePermiso('purchasing.proveedores.gestionar') ?? false);
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

    return MenuScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/branding/novapos_icon.svg', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('NovaPOS'),
          ],
        ),
        bottom: sesion == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${sesion.nombreCompleto} · ${sesion.empresaRazonSocial}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
        if (tieneAutorizarDescuentos)
          MenuCard(
            categoria: 'Ventas',
            titulo: 'Descuentos pendientes',
            subtitulo: 'Autorizar o rechazar descuentos solicitados en el POS.',
            badge: cantidadDescuentosPendientes > 0 ? cantidadDescuentosPendientes : null,
            badgeKey: const Key('badgeDescuentosPendientes'),
            onTap: () => context.push('/descuentos-pendientes'),
          ),
        MenuCard(
          categoria: 'Catálogo',
          titulo: 'Productos',
          subtitulo: 'Crear y editar Productos y Variantes.',
          onTap: () => context.push('/catalogo'),
        ),
        if (tieneClientes)
          MenuCard(
            key: const Key('homeClientesCard'),
            categoria: 'Clientes',
            titulo: 'Mantención de Clientes',
            subtitulo: 'Crear y editar Clientes.',
            onTap: () => context.push('/clientes'),
          ),
        if (tieneClientes)
          MenuCard(
            key: const Key('homeCobranzasCard'),
            categoria: 'Cobranzas',
            titulo: 'Cobranzas',
            subtitulo: 'Cargos, abonos y cuentas vencidas por Cliente.',
            onTap: () => context.push('/clientes/cobranzas'),
          ),
        if (tieneClientes)
          MenuCard(
            key: const Key('homePlazosPagoClientesCard'),
            categoria: 'Plazos de Pago',
            titulo: 'Plazos de Clientes',
            subtitulo: 'Catálogo de plazos y cuotas para vender a crédito.',
            onTap: () => context.push('/clientes/plazos-pago'),
          ),
        if (tieneAutorizarCredito)
          MenuCard(
            key: const Key('homeCreditoPendienteCard'),
            categoria: 'Clientes',
            titulo: 'Cupo de Crédito',
            subtitulo: 'Autorizar o rechazar solicitudes de crédito de Clientes.',
            badge: cantidadSolicitudesCreditoPendientes > 0 ? cantidadSolicitudesCreditoPendientes : null,
            badgeKey: const Key('badgeCreditoPendiente'),
            onTap: () => context.push('/clientes/credito-pendientes'),
          ),
        if (tieneCompras)
          MenuCard(
            key: const Key('homeComprasCard'),
            categoria: 'Compras',
            titulo: 'Proveedores y Órdenes',
            subtitulo: 'Proveedores, Órdenes de Compra y discrepancias.',
            onTap: () => context.push('/compras'),
          ),
        if (tieneCompras)
          MenuCard(
            key: const Key('homeCuentasPorPagarCard'),
            categoria: 'Compras',
            titulo: 'Cuentas por Pagar',
            subtitulo: 'Saldo, cargos y abonos por Proveedor.',
            onTap: () => context.push('/compras/cuentas-por-pagar'),
          ),
        if (tieneCompras)
          MenuCard(
            key: const Key('homePlazosPagoProveedoresCard'),
            categoria: 'Plazos de Pago',
            titulo: 'Plazos de Proveedores',
            subtitulo: 'Catálogo de plazos y cuotas para comprar a crédito.',
            onTap: () => context.push('/compras/proveedores/plazos-pago'),
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
