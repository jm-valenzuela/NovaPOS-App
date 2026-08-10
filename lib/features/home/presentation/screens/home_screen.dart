import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../customers/presentation/providers/solicitudes_credito_pendientes_providers.dart';
import '../../../sales/presentation/providers/descuentos_pendientes_providers.dart';

/// Menú principal post-login — el resto de las pantallas (Inventario,
/// Catálogo, etc.) se agregan acá como nuevas tarjetas, cada una con su
/// propia carpeta bajo lib/features/ siguiendo el mismo patrón que auth/
/// y sales/.
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

    return Scaffold(
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.point_of_sale, size: 32),
                    title: const Text('Punto de Venta'),
                    subtitle: const Text('Buscar productos, armar el carrito y cobrar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/pos'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, size: 32),
                    title: const Text('Catálogo'),
                    subtitle: const Text('Crear y editar Productos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/catalogo'),
                  ),
                ),
                if (tieneAutorizarDescuentos) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.percent, size: 32),
                      title: const Text('Descuentos pendientes'),
                      subtitle: const Text('Autorizar o rechazar descuentos solicitados en el POS'),
                      trailing: cantidadDescuentosPendientes > 0
                          ? Badge(
                              key: const Key('badgeDescuentosPendientes'),
                              label: Text('$cantidadDescuentosPendientes'),
                              child: const Icon(Icons.chevron_right),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => context.push('/descuentos-pendientes'),
                    ),
                  ),
                ],
                if (tieneClientes) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      key: const Key('homeClientesCard'),
                      leading: const Icon(Icons.people_outline, size: 32),
                      title: const Text('Clientes'),
                      subtitle: const Text('Crear y editar Clientes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/clientes'),
                    ),
                  ),
                ],
                if (tieneAutorizarCredito) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      key: const Key('homeCreditoPendienteCard'),
                      leading: const Icon(Icons.request_quote_outlined, size: 32),
                      title: const Text('Cupo de Crédito'),
                      subtitle: const Text('Autorizar o rechazar solicitudes de crédito de Clientes'),
                      trailing: cantidadSolicitudesCreditoPendientes > 0
                          ? Badge(
                              key: const Key('badgeCreditoPendiente'),
                              label: Text('$cantidadSolicitudesCreditoPendientes'),
                              child: const Icon(Icons.chevron_right),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => context.push('/clientes/credito-pendientes'),
                    ),
                  ),
                ],
                if (tieneCompras) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      key: const Key('homeComprasCard'),
                      leading: const Icon(Icons.shopping_cart_outlined, size: 32),
                      title: const Text('Compras'),
                      subtitle: const Text('Proveedores, Órdenes de Compra y discrepancias'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/compras'),
                    ),
                  ),
                ],
                if (tieneInventario) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      key: const Key('homeInventarioCard'),
                      leading: const Icon(Icons.warehouse_outlined, size: 32),
                      title: const Text('Inventario'),
                      subtitle: const Text('Ajustes, Traslados y Tarjeta de Existencia'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/inventario'),
                    ),
                  ),
                ],
                if (tieneReportes) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      key: const Key('homeFlujoCajaCard'),
                      leading: const Icon(Icons.query_stats_outlined, size: 32),
                      title: const Text('Flujo de Caja'),
                      subtitle: const Text('Ingresos y egresos por período'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/reportes/flujo-caja'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
