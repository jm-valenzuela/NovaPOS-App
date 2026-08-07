import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actualizacion_providers.dart';

/// Envuelve toda la app (ver MaterialApp.router.builder en main.dart) —
/// si se detectó una versión nueva publicada, muestra una franja fija
/// arriba de cualquier pantalla con un botón para recargar. Sin botón de
/// cerrar a propósito: no tiene sentido seguir usando una versión vieja
/// del POS con el backend ya actualizado, pero tampoco se fuerza el
/// reload solo (podría cortar una venta a medio hacer).
class BannerActualizacion extends ConsumerWidget {
  const BannerActualizacion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hayActualizacion = ref.watch(actualizacionDisponibleProvider);

    return Column(
      children: [
        if (hayActualizacion)
          Material(
            color: Colors.amber.shade800,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.system_update, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hay una nueva versión de NovaPOS disponible.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      key: const Key('actualizacionRecargar'),
                      onPressed: () => ref.read(actualizacionDisponibleProvider.notifier).recargar(),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
