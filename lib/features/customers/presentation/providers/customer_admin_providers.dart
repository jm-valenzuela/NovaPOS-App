import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;
import '../../domain/customer_repository.dart';
import '../../domain/models/cliente_resumen.dart';
import '../../domain/models/plazo_pago.dart';

class ClientesAdminState {
  const ClientesAdminState({this.clientes = const [], this.cargando = false, this.error});

  final List<ClienteResumen> clientes;
  final bool cargando;
  final String? error;

  ClientesAdminState copyWith({List<ClienteResumen>? clientes, bool? cargando, String? error, bool limpiarError = false}) {
    return ClientesAdminState(
      clientes: clientes ?? this.clientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Mantención de Clientes (crear/editar) — distinto del selector rápido del
/// POS (BusquedaClientesController en pos_providers.dart, con debounce):
/// acá se recarga la lista completa con el último texto buscado tras cada
/// cambio, mismo criterio que ProveedoresController.
class ClientesAdminController extends StateNotifier<ClientesAdminState> {
  ClientesAdminController(this._repository) : super(const ClientesAdminState()) {
    cargar();
  }

  final CustomerRepository _repository;
  String _ultimoTexto = '';

  Future<void> cargar({String? texto}) async {
    if (texto != null) _ultimoTexto = texto;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final clientes = await _repository.buscarClientes(texto: _ultimoTexto.isEmpty ? null : _ultimoTexto);
      state = state.copyWith(clientes: clientes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> crear({
    required String nombre,
    String? rut,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    try {
      await _repository.crearCliente(
        nombre: nombre,
        rut: rut,
        email: email,
        telefono: telefono,
        cupoCredito: cupoCredito,
        plazoPagoId: plazoPagoId,
        giro: giro,
        direccion: direccion,
        comuna: comuna,
        ciudad: ciudad,
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> actualizar({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    try {
      await _repository.actualizarCliente(
        clienteId: clienteId,
        nombre: nombre,
        email: email,
        telefono: telefono,
        cupoCredito: cupoCredito,
        plazoPagoId: plazoPagoId,
        giro: giro,
        direccion: direccion,
        comuna: comuna,
        ciudad: ciudad,
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Completa el Rut de un Cliente que quedó sin uno (ej. creado antes de que el alta lo exigiera).
  Future<bool> asignarRut({required String clienteId, required String rut}) async {
    try {
      await _repository.asignarRutCliente(clienteId: clienteId, rut: rut);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Dispara la evaluación de Cupo de Crédito — no lo otorga de inmediato,
  /// ver SolicitarCreditoDialog. Deja que el error se propague (el diálogo
  /// lo muestra inline) en vez de guardarlo en el estado de la lista.
  Future<void> solicitarCredito({
    required String clienteId,
    required double cupoSolicitado,
    String? plazoPagoIdSolicitado,
    String? observacion,
  }) async {
    await _repository.solicitarCreditoCliente(
      clienteId: clienteId,
      cupoSolicitado: cupoSolicitado,
      plazoPagoIdSolicitado: plazoPagoIdSolicitado,
      observacion: observacion,
    );
    await cargar();
  }
}

final clientesAdminProvider = StateNotifierProvider.autoDispose<ClientesAdminController, ClientesAdminState>((ref) {
  return ClientesAdminController(ref.watch(customerRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Plazos de Pago (Clientes)
// ---------------------------------------------------------------------------

class PlazosPagoState {
  const PlazosPagoState({this.plazos = const [], this.cargando = false, this.error});

  final List<PlazoPago> plazos;
  final bool cargando;
  final String? error;

  PlazosPagoState copyWith({List<PlazoPago>? plazos, bool? cargando, String? error, bool limpiarError = false}) {
    return PlazosPagoState(
      plazos: plazos ?? this.plazos,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Catálogo de Plazos de Pago de Clientes — mantención propia, separada del
/// alta/edición de Clientes (ver ClienteFormDialog, que solo elige de la
/// lista ya cargada acá).
class PlazosPagoController extends StateNotifier<PlazosPagoState> {
  PlazosPagoController(this._repository) : super(const PlazosPagoState()) {
    cargar();
  }

  final CustomerRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final plazos = await _repository.listarPlazosPago();
      state = state.copyWith(plazos: plazos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> crear({required String nombre, required List<int> diasCuotas}) async {
    try {
      await _repository.crearPlazoPago(nombre: nombre, diasCuotas: diasCuotas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> activar(String plazoPagoId) async {
    await _repository.activarPlazoPago(plazoPagoId);
    await cargar();
  }

  Future<void> desactivar(String plazoPagoId) async {
    await _repository.desactivarPlazoPago(plazoPagoId);
    await cargar();
  }
}

final plazosPagoProvider = StateNotifierProvider.autoDispose<PlazosPagoController, PlazosPagoState>((ref) {
  return PlazosPagoController(ref.watch(customerRepositoryProvider));
});
