import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registro_empresa_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/catalog/presentation/screens/productos_admin_screen.dart';
import '../../features/customers/presentation/screens/clientes_admin_screen.dart';
import '../../features/customers/presentation/screens/plazos_pago_screen.dart';
import '../../features/customers/presentation/screens/solicitudes_credito_pendientes_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/inventory/presentation/screens/ajustes_inventario_screen.dart';
import '../../features/inventory/presentation/screens/inventario_hub_screen.dart';
import '../../features/inventory/presentation/screens/kardex_screen.dart';
import '../../features/inventory/presentation/screens/toma_inventario_detalle_screen.dart';
import '../../features/inventory/presentation/screens/traslado_detalle_screen.dart';
import '../../features/inventory/presentation/screens/traslados_inventario_screen.dart';
import '../../features/purchasing/presentation/screens/compras_hub_screen.dart';
import '../../features/purchasing/presentation/screens/discrepancias_screen.dart';
import '../../features/purchasing/presentation/screens/documentos_recibidos_screen.dart';
import '../../features/purchasing/presentation/screens/orden_compra_detalle_screen.dart';
import '../../features/purchasing/presentation/screens/ordenes_compra_screen.dart';
import '../../features/purchasing/presentation/screens/plazos_pago_proveedor_screen.dart';
import '../../features/purchasing/presentation/screens/proveedores_screen.dart';
import '../../features/receivables/presentation/screens/cobranzas_screen.dart';
import '../../features/receivables/presentation/screens/detalle_cuenta_cliente_screen.dart';
import '../../features/sales/presentation/screens/descuentos_pendientes_screen.dart';
import '../../features/sales/presentation/screens/pos_screen.dart';

/// GoRouter reconstruido cada vez que cambia AuthState (watch, no read) —
/// simple y suficiente para el tamaño actual de la app (4 rutas); si el
/// árbol de navegación crece mucho, migrar a GoRouterRefreshStream para
/// no perder el stack de navegación en cada cambio de sesión.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final ubicacion = state.matchedLocation;

      if (authState.status == AuthStatus.desconocido) {
        return ubicacion == '/' ? null : '/';
      }

      final autenticado = authState.status == AuthStatus.autenticado;
      final vaAFlujoDeAcceso = ubicacion == '/login' || ubicacion == '/registro-empresa';

      if (!autenticado) {
        return vaAFlujoDeAcceso ? null : '/login';
      }

      if (ubicacion == '/' || vaAFlujoDeAcceso) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/registro-empresa', builder: (context, state) => const RegistroEmpresaScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
      GoRoute(path: '/catalogo', builder: (context, state) => const ProductosAdminScreen()),
      GoRoute(path: '/descuentos-pendientes', builder: (context, state) => const DescuentosPendientesScreen()),
      GoRoute(path: '/clientes', builder: (context, state) => const ClientesAdminScreen()),
      GoRoute(
          path: '/clientes/credito-pendientes', builder: (context, state) => const SolicitudesCreditoPendientesScreen()),
      GoRoute(path: '/clientes/plazos-pago', builder: (context, state) => const PlazosPagoScreen()),
      GoRoute(path: '/clientes/cobranzas', builder: (context, state) => const CobranzasScreen()),
      GoRoute(
        path: '/clientes/cobranzas/:id',
        builder: (context, state) => DetalleCuentaClienteScreen(clienteId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/compras', builder: (context, state) => const ComprasHubScreen()),
      GoRoute(path: '/compras/proveedores', builder: (context, state) => const ProveedoresScreen()),
      GoRoute(path: '/compras/proveedores/plazos-pago', builder: (context, state) => const PlazosPagoProveedorScreen()),
      GoRoute(path: '/compras/ordenes', builder: (context, state) => const OrdenesCompraScreen()),
      GoRoute(
        path: '/compras/ordenes/:id',
        builder: (context, state) => OrdenCompraDetalleScreen(ordenCompraId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/compras/proveedores/:id/documentos',
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return DocumentosRecibidosScreen(
            proveedorId: state.pathParameters['id']!,
            proveedorNombre: extra?['nombre'] ?? '',
            rutProveedor: extra?['rut'],
          );
        },
      ),
      GoRoute(path: '/compras/discrepancias', builder: (context, state) => const DiscrepanciasScreen()),
      GoRoute(path: '/inventario', builder: (context, state) => const InventarioHubScreen()),
      GoRoute(path: '/inventario/ajustes', builder: (context, state) => const AjustesInventarioScreen()),
      GoRoute(
        path: '/inventario/ajustes/:id',
        builder: (context, state) => TomaInventarioDetalleScreen(tomaId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/inventario/traslados', builder: (context, state) => const TrasladosInventarioScreen()),
      GoRoute(
        path: '/inventario/traslados/:id',
        builder: (context, state) => TrasladoDetalleScreen(trasladoId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/inventario/kardex', builder: (context, state) => const KardexScreen()),
    ],
  );
});
