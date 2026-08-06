import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Menú de Compras — mismo criterio que Home: cada sección es una tarjeta
/// que empuja su propia ruta, en vez de meter Proveedores/Órdenes/
/// Discrepancias como 3 tarjetas sueltas en el Home principal.
class ComprasHubScreen extends StatelessWidget {
  const ComprasHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras')),
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
                    key: const Key('comprasProveedoresCard'),
                    leading: const Icon(Icons.local_shipping_outlined, size: 32),
                    title: const Text('Proveedores'),
                    subtitle: const Text('Crear y editar Proveedores'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/compras/proveedores'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('comprasOrdenesCard'),
                    leading: const Icon(Icons.shopping_cart_outlined, size: 32),
                    title: const Text('Órdenes de Compra'),
                    subtitle: const Text('Crear, enviar y recibir Órdenes de Compra'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/compras/ordenes'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const Key('comprasDiscrepanciasCard'),
                    leading: const Icon(Icons.warning_amber_outlined, size: 32),
                    title: const Text('Discrepancias'),
                    subtitle: const Text('Diferencias entre lo negociado y el documento del Proveedor'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/compras/discrepancias'),
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
