import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../customers/presentation/providers/solicitudes_credito_pendientes_providers.dart';
import '../../../sales/presentation/providers/descuentos_pendientes_providers.dart';

/// Menú principal post-login — una grilla de tarjetas, cada una con su
/// propia etiqueta de categoría (Ventas, Clientes, Compras, etc.), en vez
/// de una lista plana. El resto de las pantallas se agregan acá como
/// nuevas tarjetas, cada una con su propia carpeta bajo lib/features/
/// siguiendo el mismo patrón que auth/ y sales/.
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
      backgroundColor: _HomeColores.fondoPagina,
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _TarjetaMenu(
                  categoria: 'Ventas',
                  titulo: 'Punto de Venta',
                  subtitulo: 'Buscar productos, armar el carrito y cobrar.',
                  onTap: () => context.push('/pos'),
                ),
                if (tieneAutorizarDescuentos)
                  _TarjetaMenu(
                    categoria: 'Ventas',
                    titulo: 'Descuentos pendientes',
                    subtitulo: 'Autorizar o rechazar descuentos solicitados en el POS.',
                    badge: cantidadDescuentosPendientes > 0 ? cantidadDescuentosPendientes : null,
                    badgeKey: const Key('badgeDescuentosPendientes'),
                    onTap: () => context.push('/descuentos-pendientes'),
                  ),
                _TarjetaMenu(
                  categoria: 'Catálogo',
                  titulo: 'Productos',
                  subtitulo: 'Crear y editar Productos y Variantes.',
                  onTap: () => context.push('/catalogo'),
                ),
                if (tieneClientes)
                  _TarjetaMenu(
                    key: const Key('homeClientesCard'),
                    categoria: 'Clientes',
                    titulo: 'Mantención de Clientes',
                    subtitulo: 'Crear y editar Clientes.',
                    onTap: () => context.push('/clientes'),
                  ),
                if (tieneAutorizarCredito)
                  _TarjetaMenu(
                    key: const Key('homeCreditoPendienteCard'),
                    categoria: 'Clientes',
                    titulo: 'Cupo de Crédito',
                    subtitulo: 'Autorizar o rechazar solicitudes de crédito de Clientes.',
                    badge: cantidadSolicitudesCreditoPendientes > 0 ? cantidadSolicitudesCreditoPendientes : null,
                    badgeKey: const Key('badgeCreditoPendiente'),
                    onTap: () => context.push('/clientes/credito-pendientes'),
                  ),
                if (tieneClientes)
                  _TarjetaMenu(
                    key: const Key('homeCobranzasCard'),
                    categoria: 'Cobranzas',
                    titulo: 'Cobranzas',
                    subtitulo: 'Cargos, abonos y cuentas vencidas por Cliente.',
                    onTap: () => context.push('/clientes/cobranzas'),
                  ),
                if (tieneClientes)
                  _TarjetaMenu(
                    key: const Key('homePlazosPagoClientesCard'),
                    categoria: 'Plazos de Pago',
                    titulo: 'Plazos de Clientes',
                    subtitulo: 'Catálogo de plazos y cuotas para vender a crédito.',
                    onTap: () => context.push('/clientes/plazos-pago'),
                  ),
                if (tieneCompras)
                  _TarjetaMenu(
                    key: const Key('homeComprasCard'),
                    categoria: 'Compras',
                    titulo: 'Proveedores y Órdenes',
                    subtitulo: 'Proveedores, Órdenes de Compra y discrepancias.',
                    onTap: () => context.push('/compras'),
                  ),
                if (tieneCompras)
                  _TarjetaMenu(
                    key: const Key('homeCuentasPorPagarCard'),
                    categoria: 'Compras',
                    titulo: 'Cuentas por Pagar',
                    subtitulo: 'Saldo, cargos y abonos por Proveedor.',
                    onTap: () => context.push('/compras/cuentas-por-pagar'),
                  ),
                if (tieneCompras)
                  _TarjetaMenu(
                    key: const Key('homePlazosPagoProveedoresCard'),
                    categoria: 'Plazos de Pago',
                    titulo: 'Plazos de Proveedores',
                    subtitulo: 'Catálogo de plazos y cuotas para comprar a crédito.',
                    onTap: () => context.push('/compras/proveedores/plazos-pago'),
                  ),
                if (tieneInventario)
                  _TarjetaMenu(
                    key: const Key('homeInventarioCard'),
                    categoria: 'Inventario',
                    titulo: 'Stock en tiempo real',
                    subtitulo: 'Ajustes, Traslados y Tarjeta de Existencia.',
                    onTap: () => context.push('/inventario'),
                  ),
                if (tieneReportes)
                  _TarjetaMenu(
                    key: const Key('homeFlujoCajaCard'),
                    categoria: 'Reportes',
                    titulo: 'Flujo de Caja',
                    subtitulo: 'Ingresos y egresos por período.',
                    onTap: () => context.push('/reportes/flujo-caja'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeColores {
  _HomeColores._();

  static const fondoPagina = Color(0xFFF2ECE0);
  static const tarjeta = Color(0xFF14233A);
  static const acento = Color(0xFFE58A3D);
  static const subtitulo = Color(0xFFAAB8CB);
}

/// Tarjeta oscura con etiqueta de categoría — cada una es autocontenida
/// (no depende de un encabezado de sección compartido), así que se
/// acomodan en un `Wrap` que fluye a 1 columna en pantallas angostas tipo
/// celular y hasta 3-4 en pantallas anchas tipo desktop/web.
class _TarjetaMenu extends StatelessWidget {
  const _TarjetaMenu({
    super.key,
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.badge,
    this.badgeKey,
  });

  final String categoria;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final int? badge;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        color: _HomeColores.tarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria.toUpperCase(),
                        style: const TextStyle(
                          color: _HomeColores.acento,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        key: badgeKey,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _HomeColores.acento,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitulo,
                  style: const TextStyle(color: _HomeColores.subtitulo, fontSize: 14, height: 1.35),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
