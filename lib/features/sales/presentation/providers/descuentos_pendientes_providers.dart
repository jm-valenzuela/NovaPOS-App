import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/descuento_pendiente.dart';
import '../../domain/models/detalle_descuento_pendiente.dart';
import '../../domain/sales_repository.dart';
import 'pos_providers.dart' show salesRepositoryProvider;

class DescuentosPendientesState {
  const DescuentosPendientesState({
    this.pendientes = const [],
    this.cargando = false,
    this.error,
    this.procesando = const {},
  });

  final List<DescuentoPendiente> pendientes;
  final bool cargando;
  final String? error;

  /// VentaIds con un autorizar/rechazar en curso — para deshabilitar solo
  /// los botones de esa fila, no la pantalla completa.
  final Set<String> procesando;

  DescuentosPendientesState copyWith({
    List<DescuentoPendiente>? pendientes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    Set<String>? procesando,
  }) {
    return DescuentosPendientesState(
      pendientes: pendientes ?? this.pendientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      procesando: procesando ?? this.procesando,
    );
  }
}

/// Pantalla del Supervisor (permiso "sales.descuentos.autorizar") — sirve
/// tanto si está parado junto al Cajero como si está en la oficina, es la
/// misma cola de trabajo en los dos casos.
class DescuentosPendientesController extends StateNotifier<DescuentosPendientesState> {
  DescuentosPendientesController(this._repository) : super(const DescuentosPendientesState()) {
    cargar();
  }

  final SalesRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final pendientes = await _repository.listarDescuentosPendientes();
      state = state.copyWith(pendientes: pendientes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> autorizar(String ventaId) async {
    state = state.copyWith(procesando: {...state.procesando, ventaId}, limpiarError: true);
    try {
      await _repository.autorizarDescuentoGeneral(ventaId);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(ventaId));
    }
  }

  Future<void> rechazar(String ventaId, String motivo) async {
    state = state.copyWith(procesando: {...state.procesando, ventaId}, limpiarError: true);
    try {
      await _repository.rechazarDescuentoGeneral(ventaId: ventaId, motivo: motivo);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(ventaId));
    }
  }
}

final descuentosPendientesProvider =
    StateNotifierProvider.autoDispose<DescuentosPendientesController, DescuentosPendientesState>((ref) {
  return DescuentosPendientesController(ref.watch(salesRepositoryProvider));
});

/// "Ver más" de una fila puntual — parametrizado por VentaId para no
/// acoplarlo al estado de la lista completa; se pide recién cuando el
/// Supervisor lo abre, no de entrada para toda la cola.
final detalleDescuentoPendienteProvider =
    FutureProvider.autoDispose.family<DetalleDescuentoPendiente, String>((ref, ventaId) {
  return ref.watch(salesRepositoryProvider).obtenerDetalleDescuentoPendiente(ventaId);
});
