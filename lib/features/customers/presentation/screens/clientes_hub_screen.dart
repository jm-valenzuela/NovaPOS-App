import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';

/// Menú de Clientes — mismo criterio que Home/ComprasHubScreen (misma
/// `MenuCard`/`MenuScaffold`, ver core/widgets/menu_card.dart): cada
/// sección es una tarjeta que empuja su propia ruta. Cupo de Crédito
/// queda fuera de este hub (tarjeta aparte en Home) para que su cola de
/// autorización con burbuja de pendientes siga visible a simple vista,
/// mismo criterio que "Descuentos pendientes".
class ClientesHubScreen extends StatelessWidget {
  const ClientesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuScaffold(
      appBar: AppBar(title: const Text('Clientes')),
      tarjetas: [
        MenuCard(
          key: const Key('clientesMantencionCard'),
          categoria: 'Clientes',
          titulo: 'Mantención de Clientes',
          subtitulo: 'Crear y editar Clientes.',
          onTap: () => context.push('/clientes/mantencion'),
        ),
        MenuCard(
          key: const Key('clientesCuentasPorCobrarCard'),
          categoria: 'Clientes',
          titulo: 'Cuentas x Cobrar',
          subtitulo: 'Cargos, abonos y cuentas vencidas por Cliente.',
          onTap: () => context.push('/clientes/cobranzas'),
        ),
        MenuCard(
          key: const Key('clientesPlazosPagoCard'),
          categoria: 'Plazos de Pago',
          titulo: 'Plazos de Clientes',
          subtitulo: 'Catálogo de plazos y cuotas para vender a crédito.',
          onTap: () => context.push('/clientes/plazos-pago'),
        ),
      ],
    );
  }
}
