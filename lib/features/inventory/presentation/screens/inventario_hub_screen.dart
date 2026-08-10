import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Menú de Inventario — mismo criterio que ComprasHubScreen: cada sección
/// es una tarjeta que empuja su propia ruta.
class InventarioHubScreen extends StatelessWidget {
  const InventarioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
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
                    key: const Key('inventarioAjustesCard'),
                    leading: const Icon(Icons.fact_check_outlined, size: 32),
                    title: const Text('Ajustes de Inventario'),
                    subtitle: const Text('Contar existencias y aplicar diferencias'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/inventario/ajustes'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('inventarioTrasladosCard'),
                    leading: const Icon(Icons.swap_horiz, size: 32),
                    title: const Text('Traslados'),
                    subtitle: const Text('Mover mercadería entre Bodegas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/inventario/traslados'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('inventarioKardexCard'),
                    leading: const Icon(Icons.receipt_long_outlined, size: 32),
                    title: const Text('Tarjeta de Existencia'),
                    subtitle: const Text('Historial de movimientos de un Producto'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/inventario/kardex'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
