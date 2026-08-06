import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;
import '../../domain/customer_repository.dart';
import '../../domain/models/cliente_resumen.dart';

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
    int plazoPagoDias = 0,
  }) async {
    try {
      await _repository.crearCliente(nombre: nombre, rut: rut, email: email, telefono: telefono, cupoCredito: cupoCredito, plazoPagoDias: plazoPagoDias);
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
    int plazoPagoDias = 0,
  }) async {
    try {
      await _repository.actualizarCliente(
          clienteId: clienteId, nombre: nombre, email: email, telefono: telefono, cupoCredito: cupoCredito, plazoPagoDias: plazoPagoDias);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final clientesAdminProvider = StateNotifierProvider.autoDispose<ClientesAdminController, ClientesAdminState>((ref) {
  return ClientesAdminController(ref.watch(customerRepositoryProvider));
});
