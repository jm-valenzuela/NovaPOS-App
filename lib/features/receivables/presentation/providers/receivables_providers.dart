import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../sales/domain/models/venta_enums.dart';
import '../../data/receivables_api.dart';
import '../../data/receivables_repository_impl.dart';
import '../../domain/models/cliente_cobranza.dart';
import '../../domain/models/cuenta_por_cobrar_detalle.dart';
import '../../domain/receivables_repository.dart';

final receivablesApiProvider = Provider<ReceivablesApi>((ref) => ReceivablesApi(ref.watch(apiClientProvider)));

final receivablesRepositoryProvider =
    Provider<ReceivablesRepository>((ref) => ReceivablesRepositoryImpl(ref.watch(receivablesApiProvider)));

class CobranzaState {
  const CobranzaState({this.clientes = const [], this.cargando = false, this.error});

  final List<ClienteCobranza> clientes;
  final bool cargando;
  final String? error;

  CobranzaState copyWith({List<ClienteCobranza>? clientes, bool? cargando, String? error, bool limpiarError = false}) {
    return CobranzaState(
      clientes: clientes ?? this.clientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Listado global de Cobranzas — ya viene ordenado del backend (más
/// atrasado primero, ver ListarCobranzaQuery).
class CobranzaController extends StateNotifier<CobranzaState> {
  CobranzaController(this._repository) : super(const CobranzaState()) {
    cargar();
  }

  final ReceivablesRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final clientes = await _repository.listarCobranza();
      state = state.copyWith(clientes: clientes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final cobranzaProvider = StateNotifierProvider.autoDispose<CobranzaController, CobranzaState>((ref) {
  return CobranzaController(ref.watch(receivablesRepositoryProvider));
});

class DetalleCuentaState {
  const DetalleCuentaState({this.detalle, this.cargando = true, this.error});

  final CuentaPorCobrarDetalle? detalle;
  final bool cargando;
  final String? error;

  DetalleCuentaState copyWith({
    CuentaPorCobrarDetalle? detalle,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return DetalleCuentaState(
      detalle: detalle ?? this.detalle,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Detalle de la Cuenta por Cobrar de un Cliente puntual — familia por
/// clienteId (un controller nuevo por cada detalle abierto, mismo patrón
/// que otras pantallas de detalle del proyecto).
class DetalleCuentaController extends StateNotifier<DetalleCuentaState> {
  DetalleCuentaController(this._repository, this._clienteId) : super(const DetalleCuentaState()) {
    cargar();
  }

  final ReceivablesRepository _repository;
  final String _clienteId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final detalle = await _repository.obtenerCuenta(_clienteId);
      state = state.copyWith(detalle: detalle, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> registrarAbono({required double monto, required MedioPago medioPago, String? motivo}) async {
    try {
      await _repository.registrarAbono(clienteId: _clienteId, monto: monto, medioPago: medioPago, motivo: motivo);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final detalleCuentaProvider =
    StateNotifierProvider.autoDispose.family<DetalleCuentaController, DetalleCuentaState, String>((ref, clienteId) {
  return DetalleCuentaController(ref.watch(receivablesRepositoryProvider), clienteId);
});
