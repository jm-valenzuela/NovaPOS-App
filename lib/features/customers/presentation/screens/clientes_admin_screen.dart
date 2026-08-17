import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_observer.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/cliente_resumen.dart';
import '../../domain/models/plazo_pago.dart';
import '../providers/customer_admin_providers.dart';
import '../widgets/cliente_form_dialog.dart';
import '../widgets/solicitar_credito_dialog.dart';

class ClientesAdminScreen extends ConsumerStatefulWidget {
  const ClientesAdminScreen({super.key});

  @override
  ConsumerState<ClientesAdminScreen> createState() => _ClientesAdminScreenState();
}

class _ClientesAdminScreenState extends ConsumerState<ClientesAdminScreen> with RouteAware {
  final _busquedaController = TextEditingController();

  /// Refresca en silencio cada 20s (mismo intervalo que HomeScreen para sus
  /// contadores pendientes) — cubre el caso de dos pestañas/dispositivos
  /// distintos abiertos a la vez (ej. alguien autoriza un Cupo de Crédito
  /// desde otra pestaña duplicada): sin esto, esta pantalla nunca se entera
  /// porque no comparte memoria con la otra pestaña y aquí nunca ocurre
  /// ninguna navegación que dispare didPopNext. No usa `cargando` para no
  /// mostrar el spinner de carga completa (ver estado.clientes.isEmpty en
  /// build) — solo reemplaza la lista calladamente si algo cambió.
  Timer? _pollSilencioso;

  @override
  void initState() {
    super.initState();
    _pollSilencioso = Timer.periodic(const Duration(seconds: 20), (_) {
      ref.read(clientesAdminProvider.notifier).cargar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _pollSilencioso?.cancel();
    routeObserver.unsubscribe(this);
    _busquedaController.dispose();
    super.dispose();
  }

  /// Se llama cuando esta pantalla vuelve a quedar visible porque la ruta
  /// empujada encima (ej. SolicitudesCreditoPendientesScreen, alcanzada
  /// desde Home) se cerró — el permiso "customers.clientes.autorizarcredito"
  /// pudo haber autorizado un Cupo de Crédito mientras tanto y esta lista
  /// debe reflejarlo sin que el Usuario tenga que recargar la página.
  @override
  void didPopNext() => ref.read(clientesAdminProvider.notifier).cargar();

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(clientesAdminProvider);
    final plazos = ref.watch(plazosPagoProvider).plazos;

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoClienteBoton'),
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('clientesBusqueda'),
              controller: _busquedaController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o RUT...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (texto) => ref.read(clientesAdminProvider.notifier).cargar(texto: texto),
            ),
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(clientesAdminProvider.notifier).cargar(),
              child: estado.cargando && estado.clientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : estado.clientes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Sin Clientes'))),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: estado.clientes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final cliente = estado.clientes[index];
                            return ListTile(
                              key: Key('cliente_${cliente.id}'),
                              title: Text(cliente.nombre),
                              subtitle: Text(_subtitulo(cliente, plazos)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: Key('clienteSolicitarCredito_${cliente.id}'),
                                    icon: const Icon(Icons.request_quote_outlined),
                                    tooltip: 'Solicitar Cupo de Crédito',
                                    onPressed: cliente.tieneSolicitudCreditoPendiente
                                        ? null
                                        : () => showDialog<void>(
                                              context: context,
                                              builder: (_) => SolicitarCreditoDialog(cliente: cliente),
                                            ),
                                  ),
                                  const Icon(Icons.edit_outlined),
                                ],
                              ),
                              onTap: () => _abrirFormulario(context, existente: cliente),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitulo(ClienteResumen cliente, List<PlazoPago> plazos) {
    final rut = cliente.rut ?? 'Sin RUT';
    if (cliente.tieneSolicitudCreditoPendiente) return '$rut · Crédito pendiente de autorización';
    if (cliente.cupoCredito > 0) {
      return '$rut · Cupo: ${MonedaFormatter.formatear(cliente.cupoCredito)} · ${_nombrePlazo(cliente.plazoPagoId, plazos)}';
    }
    return rut;
  }

  String _nombrePlazo(String? plazoPagoId, List<PlazoPago> plazos) {
    if (plazoPagoId == null) return 'Inmediato';
    for (final plazo in plazos) {
      if (plazo.id == plazoPagoId) return plazo.nombre;
    }
    return 'Plazo de pago';
  }

  Future<void> _abrirFormulario(BuildContext context, {ClienteResumen? existente}) async {
    await showDialog<bool>(context: context, builder: (_) => ClienteFormDialog(existente: existente));
  }
}
