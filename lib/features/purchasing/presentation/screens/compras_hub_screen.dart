import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Compras — mismo criterio que Home (misma `MenuCard`/
/// `MenuScaffold`, ver core/widgets/menu_card.dart): cada sección es una
/// tarjeta que empuja su propia ruta, en vez de meter Proveedores/
/// Órdenes/Discrepancias como tarjetas sueltas en el Home principal.
class ComprasHubScreen extends StatelessWidget {
  const ComprasHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Compras')),
      tarjetas: [
        MenuCard(
          key: const Key('comprasProveedoresCard'),
          categoria: 'Compras',
          titulo: 'Proveedores',
          subtitulo: 'Crear y editar Proveedores.',
          onTap: () => context.push('/compras/proveedores'),
        ),
        MenuCard(
          key: const Key('comprasOrdenesCard'),
          categoria: 'Compras',
          titulo: 'Órdenes de Compra',
          subtitulo: 'Crear, enviar y recibir Órdenes de Compra.',
          onTap: () => context.push('/compras/ordenes'),
        ),
        MenuCard(
          key: const Key('comprasDiscrepanciasCard'),
          categoria: 'Compras',
          titulo: 'Discrepancias',
          subtitulo: 'Diferencias entre lo negociado y el documento del Proveedor.',
          onTap: () => context.push('/compras/discrepancias'),
        ),
        MenuCard(
          key: const Key('comprasCuentasPorPagarCard'),
          categoria: 'Proveedores',
          titulo: 'Cuentas por Pagar',
          subtitulo: 'Saldo, cargos y abonos por Proveedor.',
          onTap: () => context.push('/compras/cuentas-por-pagar'),
        ),
        MenuCard(
          key: const Key('comprasPlazosPagoCard'),
          categoria: 'Plazos de Pago',
          titulo: 'Plazos de Proveedores',
          subtitulo: 'Catálogo de plazos y cuotas para comprar a crédito.',
          onTap: () => context.push('/compras/proveedores/plazos-pago'),
        ),
      ],
    );
  }
}
