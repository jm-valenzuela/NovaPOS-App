import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// Placeholder post-login — el resto de las pantallas (Venta, Inventario,
/// etc.) se agregan acá como próximos features, cada una con su propia
/// carpeta bajo lib/features/ siguiendo el mismo patrón que auth/.
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
      body: const Center(
        child: Text('Sesión iniciada — próximas pantallas van acá.'),
      ),
    );
  }
}
