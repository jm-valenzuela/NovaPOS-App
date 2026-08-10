import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/reporting_api.dart';
import '../../data/reporting_repository_impl.dart';
import '../../domain/models/flujo_caja_dia.dart';
import '../../domain/reporting_repository.dart';

final reportingApiProvider = Provider<ReportingApi>((ref) => ReportingApi(ref.watch(apiClientProvider)));

final reportingRepositoryProvider =
    Provider<ReportingRepository>((ref) => ReportingRepositoryImpl(ref.watch(reportingApiProvider)));

class FlujoCajaState {
  const FlujoCajaState({required this.desde, required this.hasta, this.dias = const [], this.cargando = false, this.error});

  final DateTime desde;
  final DateTime hasta;
  final List<FlujoCajaDia> dias;
  final bool cargando;
  final String? error;

  FlujoCajaState copyWith({
    DateTime? desde,
    DateTime? hasta,
    List<FlujoCajaDia>? dias,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) {
    return FlujoCajaState(
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      dias: dias ?? this.dias,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Flujo de Caja por período — arranca con el mes calendario en curso
/// (primer día del mes hasta hoy) y se puede recargar con un rango
/// distinto vía `cambiarPeriodo`. Ver FlujoCajaQuery/ObtenerFlujoCajaAsync
/// en el backend para el criterio Real vs Proyectado.
class FlujoCajaController extends StateNotifier<FlujoCajaState> {
  FlujoCajaController(this._repository)
      : super(FlujoCajaState(desde: DateTime(DateTime.now().year, DateTime.now().month, 1), hasta: _hoy())) {
    cargar();
  }

  final ReportingRepository _repository;

  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final dias = await _repository.obtenerFlujoCaja(desde: state.desde, hasta: state.hasta);
      state = state.copyWith(dias: dias, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> cambiarPeriodo({required DateTime desde, required DateTime hasta}) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }
}

final flujoCajaProvider = StateNotifierProvider.autoDispose<FlujoCajaController, FlujoCajaState>((ref) {
  return FlujoCajaController(ref.watch(reportingRepositoryProvider));
});
