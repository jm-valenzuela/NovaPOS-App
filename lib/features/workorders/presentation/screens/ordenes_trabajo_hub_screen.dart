import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Órdenes de Trabajo — mismo criterio que ClientesHubScreen/
/// ComprasHubScreen: cada sección es una tarjeta que empuja su propia
/// ruta. Operarios queda acá (no en Home) porque es un concepto propio de
/// Órdenes de Trabajo — quién ejecuta los Ítems, ver AsignarOperadorDialog.
class OrdenesTrabajoHubScreen extends StatelessWidget {
  const OrdenesTrabajoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Órdenes de Trabajo')),
      tarjetas: [
        MenuCard(
          key: const Key('ordenesTrabajoListadoCard'),
          categoria: 'Órdenes de Trabajo',
          titulo: 'Gestión de Órdenes',
          subtitulo: 'Recibir, cotizar y hacer seguimiento a cada Orden.',
          onTap: () => context.push('/ordenes-trabajo/listado'),
        ),
        MenuCard(
          key: const Key('ordenesTrabajoOperariosCard'),
          categoria: 'Operarios',
          titulo: 'Gestión de Operarios',
          subtitulo: 'Crear Operarios y ver qué Ítems tiene asignado cada uno.',
          onTap: () => context.push('/ordenes-trabajo/operarios'),
        ),
      ],
    );
  }
}
