import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cotizacion.dart';
import '../../domain/sales_repository.dart';
import 'pos_providers.dart' show salesRepositoryProvider;

class CotizacionesState {
  const CotizacionesState({this.cotizaciones = const [], this.cargando = true, this.error});

  final List<CotizacionResumen> cotizaciones;
  final bool cargando;
  final String? error;

  CotizacionesState copyWith({List<CotizacionResumen>? cotizaciones, bool? cargando, String? error, bool limpiarError = false}) {
    return CotizacionesState(
      cotizaciones: cotizaciones ?? this.cotizaciones,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Listado completo de Cotizaciones vigentes de una Sucursal — a
/// diferencia de RescatarCotizacionDialog (acotado a 10, pensado para
/// elegir rápido dentro del POS), esta pantalla es para revisarlas todas.
class CotizacionesController extends StateNotifier<CotizacionesState> {
  CotizacionesController(this._repository, this._sucursalId) : super(const CotizacionesState()) {
    cargar();
  }

  final SalesRepository _repository;
  final String _sucursalId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final cotizaciones = await _repository.listarCotizaciones(_sucursalId);
      state = state.copyWith(cotizaciones: cotizaciones, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final cotizacionesProvider =
    StateNotifierProvider.autoDispose.family<CotizacionesController, CotizacionesState, String>((ref, sucursalId) {
  return CotizacionesController(ref.watch(salesRepositoryProvider), sucursalId);
});
