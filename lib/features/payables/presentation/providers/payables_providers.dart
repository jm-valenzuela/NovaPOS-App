import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../sales/domain/models/venta_enums.dart';
import '../../data/payables_api.dart';
import '../../data/payables_repository_impl.dart';
import '../../domain/models/cuenta_por_pagar_detalle.dart';
import '../../domain/models/proveedor_por_pagar.dart';
import '../../domain/payables_repository.dart';

final payablesApiProvider = Provider<PayablesApi>((ref) => PayablesApi(ref.watch(apiClientProvider)));

final payablesRepositoryProvider =
    Provider<PayablesRepository>((ref) => PayablesRepositoryImpl(ref.watch(payablesApiProvider)));

class CuentasPorPagarState {
  const CuentasPorPagarState({this.proveedores = const [], this.cargando = false, this.error});

  final List<ProveedorPorPagar> proveedores;
  final bool cargando;
  final String? error;

  CuentasPorPagarState copyWith({
    List<ProveedorPorPagar>? proveedores,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return CuentasPorPagarState(
      proveedores: proveedores ?? this.proveedores,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Listado global de Cuentas por Pagar — ya viene ordenado del backend (más
/// atrasado primero, ver ListarCuentasPorPagarQuery).
class CuentasPorPagarController extends StateNotifier<CuentasPorPagarState> {
  CuentasPorPagarController(this._repository) : super(const CuentasPorPagarState()) {
    cargar();
  }

  final PayablesRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final proveedores = await _repository.listarCuentasPorPagar();
      state = state.copyWith(proveedores: proveedores, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final cuentasPorPagarProvider = StateNotifierProvider.autoDispose<CuentasPorPagarController, CuentasPorPagarState>((ref) {
  return CuentasPorPagarController(ref.watch(payablesRepositoryProvider));
});

class DetalleCuentaProveedorState {
  const DetalleCuentaProveedorState({this.detalle, this.cargando = true, this.error});

  final CuentaPorPagarDetalle? detalle;
  final bool cargando;
  final String? error;

  DetalleCuentaProveedorState copyWith({
    CuentaPorPagarDetalle? detalle,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return DetalleCuentaProveedorState(
      detalle: detalle ?? this.detalle,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Detalle de la Cuenta por Pagar de un Proveedor puntual — familia por
/// proveedorId (un controller nuevo por cada detalle abierto, mismo patrón
/// que otras pantallas de detalle del proyecto).
class DetalleCuentaProveedorController extends StateNotifier<DetalleCuentaProveedorState> {
  DetalleCuentaProveedorController(this._repository, this._proveedorId) : super(const DetalleCuentaProveedorState()) {
    cargar();
  }

  final PayablesRepository _repository;
  final String _proveedorId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final detalle = await _repository.obtenerCuenta(_proveedorId);
      state = state.copyWith(detalle: detalle, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> registrarPago({required double monto, required MedioPago medioPago, String? motivo}) async {
    try {
      await _repository.registrarPago(proveedorId: _proveedorId, monto: monto, medioPago: medioPago, motivo: motivo);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final detalleCuentaProveedorProvider = StateNotifierProvider.autoDispose
    .family<DetalleCuentaProveedorController, DetalleCuentaProveedorState, String>((ref, proveedorId) {
  return DetalleCuentaProveedorController(ref.watch(payablesRepositoryProvider), proveedorId);
});
