import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Compras — mismo criterio que Home (misma `MenuCard`/
/// `MenuScaffold`, ver core/widgets/menu_card.dart): cada sección es una
/// tarjeta que empuja su propia ruta, en vez de meter Proveedores/
/// Órdenes/Discrepancias como tarjetas sueltas en el Home principal.
///
/// El título del AppBar y las categorías de las tarjetas replican
/// exactamente el texto de la tarjeta "Proveedores y Órdenes" en Home
/// ("Proveedores, Cuentas x Pagar") — a pedido explícito del usuario, que
/// señaló que entrar acá mostraba un título "Compras" sin relación con lo
/// que decía la tarjeta que lo trajo. Dos grupos: "Proveedores" (todo lo
/// operativo del día a día) y "Cuentas x Pagar" (lo financiero).
class ComprasHubScreen extends StatelessWidget {
  const ComprasHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Proveedores y Órdenes')),
      tarjetas: [
        MenuCard(
          key: const Key('comprasProveedoresCard'),
          categoria: 'Proveedores',
          titulo: 'Proveedores',
          subtitulo: 'Crear y editar Proveedores.',
          onTap: () => context.push('/compras/proveedores'),
        ),
        MenuCard(
          key: const Key('comprasOrdenesCard'),
          categoria: 'Proveedores',
          titulo: 'Órdenes de Compra',
          subtitulo: 'Crear, enviar y recibir Órdenes de Compra.',
          onTap: () => context.push('/compras/ordenes'),
        ),
        MenuCard(
          key: const Key('comprasDocumentosRecibidosCard'),
          categoria: 'Proveedores',
          titulo: 'Documentos Recibidos',
          subtitulo: 'Boletas y Facturas de todos los Proveedores, en un solo lugar.',
          onTap: () => context.push('/compras/documentos-recibidos'),
        ),
        MenuCard(
          key: const Key('comprasFacturasInternasCard'),
          categoria: 'Proveedores',
          titulo: 'Facturas Internas',
          subtitulo: 'Gastos, insumos, servicios y activo fijo — facturas que no son compra de mercadería.',
          onTap: () => context.push('/facturas-internas'),
        ),
        MenuCard(
          key: const Key('comprasDiscrepanciasCard'),
          categoria: 'Proveedores',
          titulo: 'Discrepancias',
          subtitulo: 'Diferencias entre lo negociado y el documento del Proveedor.',
          onTap: () => context.push('/compras/discrepancias'),
        ),
        MenuCard(
          key: const Key('comprasCuentasPorPagarCard'),
          categoria: 'Cuentas x Pagar',
          titulo: 'Cuentas por Pagar',
          subtitulo: 'Saldo, cargos y abonos por Proveedor.',
          onTap: () => context.push('/compras/cuentas-por-pagar'),
        ),
        MenuCard(
          key: const Key('comprasPlazosPagoCard'),
          categoria: 'Cuentas x Pagar',
          titulo: 'Plazos de Proveedores',
          subtitulo: 'Catálogo de plazos y cuotas para comprar a crédito.',
          onTap: () => context.push('/compras/proveedores/plazos-pago'),
        ),
      ],
    );
  }
}
