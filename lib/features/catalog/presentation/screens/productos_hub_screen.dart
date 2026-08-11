import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Productos — mismo criterio que Home/ComprasHubScreen (misma
/// `MenuCard`/`MenuScaffold`, ver core/widgets/menu_card.dart): cada
/// sección es una tarjeta que empuja su propia ruta.
class ProductosHubScreen extends StatelessWidget {
  const ProductosHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Productos')),
      tarjetas: [
        MenuCard(
          key: const Key('productosMantencionCard'),
          categoria: 'Productos',
          titulo: 'Productos',
          subtitulo: 'Crear y editar Productos y Variantes.',
          onTap: () => context.push('/catalogo/productos'),
        ),
        MenuCard(
          key: const Key('productosMarcasCard'),
          categoria: 'Productos',
          titulo: 'Marcas',
          subtitulo: 'Crear Marcas para clasificar los Productos.',
          onTap: () => context.push('/catalogo/marcas'),
        ),
        MenuCard(
          key: const Key('productosCategoriasCard'),
          categoria: 'Productos',
          titulo: 'Categorías',
          subtitulo: 'Departamento, SubDepartamento, Clase y Subclase.',
          onTap: () => context.push('/catalogo/categorias'),
        ),
        MenuCard(
          key: const Key('productosOfertasCard'),
          categoria: 'Promociones',
          titulo: 'Ofertas para Imprimir',
          subtitulo: 'Productos en oferta vigente, listos para armar el afiche.',
          onTap: () => context.push('/catalogo/ofertas'),
        ),
      ],
    );
  }
}
