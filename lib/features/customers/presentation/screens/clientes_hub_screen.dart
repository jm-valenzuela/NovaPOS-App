import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/menu_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/solicitudes_credito_pendientes_providers.dart';

/// Menú de Clientes — mismo criterio que Home/ComprasHubScreen (misma
/// `MenuCard`/`MenuScaffold`, ver core/widgets/menu_card.dart): cada
/// sección es una tarjeta que empuja su propia ruta.
class ClientesHubScreen extends ConsumerStatefulWidget {
  const ClientesHubScreen({super.key});

  @override
  ConsumerState<ClientesHubScreen> createState() => _ClientesHubScreenState();
}

class _ClientesHubScreenState extends ConsumerState<ClientesHubScreen> {
  Timer? _pollSolicitudesCredito;

  @override
  void initState() {
    super.initState();
    _pollSolicitudesCredito = Timer.periodic(const Duration(seconds: 20), (_) {
      if (ref.read(authControllerProvider).sesion?.tienePermiso('customers.clientes.autorizarcredito') ?? false) {
        ref.read(solicitudesCreditoPendientesProvider.notifier).cargar();
      }
    });
  }

  @override
  void dispose() {
    _pollSolicitudesCredito?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authControllerProvider).sesion;
    final tieneAutorizarCredito = sesion?.tienePermiso('customers.clientes.autorizarcredito') ?? false;
    final cantidadSolicitudesCreditoPendientes =
        tieneAutorizarCredito ? ref.watch(solicitudesCreditoPendientesProvider).pendientes.length : 0;

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
          key: const Key('clientesCobranzasCard'),
          categoria: 'Cobranzas',
          titulo: 'Cobranzas',
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
        if (tieneAutorizarCredito)
          MenuCard(
            key: const Key('clientesCreditoPendienteCard'),
            categoria: 'Clientes',
            titulo: 'Cupo de Crédito',
            subtitulo: 'Autorizar o rechazar solicitudes de crédito de Clientes.',
            badge: cantidadSolicitudesCreditoPendientes > 0 ? cantidadSolicitudesCreditoPendientes : null,
            badgeKey: const Key('clientesBadgeCreditoPendiente'),
            onTap: () => context.push('/clientes/credito-pendientes'),
          ),
      ],
    );
  }
}
