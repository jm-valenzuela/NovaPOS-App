import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
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
    // Solo se observa el provider si hay permiso — evita el llamado inicial
    // a listarDescuentosPendientes() para Usuarios que ni siquiera ven la
    // tarjeta (ej. un Cajero sin el permiso).
    final cantidadDescuentosPendientes =
        tieneAutorizarDescuentos ? ref.watch(descuentosPendientesProvider).pendientes.length : 0;

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
