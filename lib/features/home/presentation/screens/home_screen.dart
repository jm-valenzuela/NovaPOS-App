import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// Menú principal post-login — el resto de las pantallas (Inventario,
/// Catálogo, etc.) se agregan acá como nuevas tarjetas, cada una con su
/// propia carpeta bajo lib/features/ siguiendo el mismo patrón que auth/
/// y sales/.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NovaPOS'),
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
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.point_of_sale, size: 32),
                title: const Text('Punto de Venta'),
                subtitle: const Text('Buscar productos, armar el carrito y cobrar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/pos'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
