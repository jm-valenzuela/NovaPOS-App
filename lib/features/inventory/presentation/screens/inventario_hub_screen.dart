import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Inventario — mismo criterio que Home/ComprasHubScreen (misma
/// `MenuCard`/`MenuScaffold`, ver core/widgets/menu_card.dart): cada
/// sección es una tarjeta que empuja su propia ruta.
class InventarioHubScreen extends StatelessWidget {
  const InventarioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Inventario')),
      tarjetas: [
        MenuCard(
          key: const Key('inventarioAjustesCard'),
          categoria: 'Inventario',
          titulo: 'Ajustes de Inventario',
          subtitulo: 'Contar existencias y aplicar diferencias.',
          onTap: () => context.push('/inventario/ajustes'),
        ),
        MenuCard(
          key: const Key('inventarioTrasladosCard'),
          categoria: 'Inventario',
          titulo: 'Traslados',
          subtitulo: 'Mover mercadería entre Bodegas.',
          onTap: () => context.push('/inventario/traslados'),
        ),
        MenuCard(
          key: const Key('inventarioKardexCard'),
          categoria: 'Inventario',
          titulo: 'Tarjeta de Existencia',
          subtitulo: 'Historial de movimientos de un Producto.',
          onTap: () => context.push('/inventario/kardex'),
        ),
      ],
    );
  }
}
