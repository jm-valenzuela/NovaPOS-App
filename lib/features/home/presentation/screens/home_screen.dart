import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _pollDescuentosPendientes = Timer.periodic(const Duration(seconds: 20), (_) {
      if (ref.read(authControllerProvider).sesion?.tienePermiso('sales.descuentos.autorizar') ?? false) {
        ref.read(descuentosPendientesProvider.notifier).cargar();
      }
    });
  }

  @override
  void dispose() {
    _pollDescuentosPendientes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authControllerProvider).sesion;
    final tieneAutorizarDescuentos = sesion?.tienePermiso('sales.descuentos.autorizar') ?? false;
    final tieneClientes = (sesion?.tienePermiso('customers.clientes.gestionar') ?? false) ||
        (sesion?.tienePermiso('customers.clientes.autorizarcredito') ?? false);
    final tieneCompras = (sesion?.tienePermiso('purchasing.ordenescompra.gestionar') ?? false) ||
        (sesion?.tienePermiso('purchasing.proveedores.gestionar') ?? false);
    final tieneInventario = sesion?.tienePermiso('inventory.stock.ver') ?? false;
    final tieneReportes = sesion?.tienePermiso('reporting.reportes.ver') ?? false;
    // Solo se observa el provider si hay permiso — evita el llamado inicial
    // a listarDescuentosPendientes() para Usuarios que ni siquiera ven la
    // tarjeta (ej. un Cajero sin el permiso).
    final cantidadDescuentosPendientes =
        tieneAutorizarDescuentos ? ref.watch(descuentosPendientesProvider).pendientes.length : 0;

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
            titulo: 'Clientes',
            subtitulo: 'Mantención, Cobranzas, Plazos de Pago y Cupo de Crédito.',
            onTap: () => context.push('/clientes'),
          ),
        if (tieneCompras)
          MenuCard(
            key: const Key('homeComprasCard'),
            categoria: 'Proveedores',
            titulo: 'Proveedores y Órdenes',
            subtitulo: 'Proveedores, Órdenes de Compra, Discrepancias, Cuentas por Pagar y Plazos de Pago.',
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
