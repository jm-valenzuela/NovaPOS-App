import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registro_empresa_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/catalog/presentation/screens/productos_admin_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
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
    ],
  );
});
