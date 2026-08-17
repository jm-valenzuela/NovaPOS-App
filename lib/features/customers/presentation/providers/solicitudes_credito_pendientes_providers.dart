import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;
import '../../domain/customer_repository.dart';
import '../../domain/models/solicitud_credito_pendiente.dart';

class SolicitudesCreditoPendientesState {
  const SolicitudesCreditoPendientesState({
    this.pendientes = const [],
    this.cargando = false,
    this.error,
    this.procesando = const {},
  });

  final List<SolicitudCreditoPendiente> pendientes;
  final bool cargando;
  final String? error;

  /// ClienteIds con un autorizar/rechazar en curso — para deshabilitar solo
  /// los botones de esa fila, no la pantalla completa.
  final Set<String> procesando;

  SolicitudesCreditoPendientesState copyWith({
    List<SolicitudCreditoPendiente>? pendientes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    Set<String>? procesando,
  }) {
    return SolicitudesCreditoPendientesState(
      pendientes: pendientes ?? this.pendientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      procesando: procesando ?? this.procesando,
    );
  }
}

/// Cola de trabajo de quien autoriza Cupo de Crédito (permiso
/// "customers.clientes.autorizarcredito") — mismo patrón que
/// DescuentosPendientesController, sirve tanto si está parado junto a
/// quien registró al Cliente como si está en la oficina.
class SolicitudesCreditoPendientesController extends StateNotifier<SolicitudesCreditoPendientesState> {
  SolicitudesCreditoPendientesController(this._repository) : super(const SolicitudesCreditoPendientesState()) {
    cargar();
  }

  final CustomerRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final pendientes = await _repository.listarSolicitudesCreditoPendientes();
      state = state.copyWith(pendientes: pendientes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> autorizar(String clienteId) async {
    state = state.copyWith(procesando: {...state.procesando, clienteId}, limpiarError: true);
    try {
      await _repository.autorizarCreditoCliente(clienteId);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(clienteId));
    }
  }

  Future<void> rechazar(String clienteId, String motivo) async {
    state = state.copyWith(procesando: {...state.procesando, clienteId}, limpiarError: true);
    try {
      await _repository.rechazarCreditoCliente(clienteId: clienteId, motivo: motivo);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(clienteId));
    }
  }
}

/// La pantalla de Clientes (ClientesAdminScreen) se refresca sola al volver
/// a quedar visible después de autorizar/rechazar acá — ver su RouteAware/
/// didPopNext — en vez de invalidar clientesAdminProvider desde este
/// controller: ese enfoque se probó primero pero es incorrecto cuando la
/// pantalla de Clientes NO está montada (el caso real: se llega acá desde
/// Home, no desde Clientes), porque invalidate() crea el
/// StateNotifierProvider.autoDispose de golpe y lo destruye de inmediato al
/// no tener watchers, y el cargar() async en curso revienta con "Tried to
/// use ClientesAdminController after dispose was called" al intentar
/// escribir estado después.
final solicitudesCreditoPendientesProvider =
    StateNotifierProvider.autoDispose<SolicitudesCreditoPendientesController, SolicitudesCreditoPendientesState>((ref) {
  return SolicitudesCreditoPendientesController(ref.watch(customerRepositoryProvider));
});
