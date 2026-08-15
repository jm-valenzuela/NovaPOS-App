import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/cash_api.dart';
import '../../data/cash_repository_impl.dart';
import '../../domain/cash_repository.dart';
import '../../domain/models/resumen_cierre_caja.dart';
import '../../domain/models/retiro_caja_pendiente.dart';
import '../../domain/models/sesion_caja.dart';

final cashApiProvider = Provider<CashApi>((ref) => CashApi(ref.watch(apiClientProvider)));

final cashRepositoryProvider = Provider<CashRepository>((ref) => CashRepositoryImpl(ref.watch(cashApiProvider)));

class SesionCajaState {
  const SesionCajaState({this.sesion, this.cargando = true, this.error});

  final SesionCaja? sesion;
  final bool cargando;
  final String? error;

  SesionCajaState copyWith({SesionCaja? sesion, bool? cargando, String? error, bool limpiarError = false}) {
    return SesionCajaState(
      sesion: sesion ?? this.sesion,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Sesión de Caja Abierta de una Caja puntual — el POS la consulta antes de
/// dejar vender (null significa que hay que Abrir Caja primero, ver
/// AbrirCajaDialog).
class SesionCajaController extends StateNotifier<SesionCajaState> {
  SesionCajaController(this._repository, this._cajaId) : super(const SesionCajaState()) {
    cargar();
  }

  final CashRepository _repository;
  final String _cajaId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final sesion = await _repository.obtenerSesionAbierta(_cajaId);
      state = state.copyWith(sesion: sesion, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> abrir(double montoInicial) async {
    try {
      await _repository.abrirCaja(cajaId: _cajaId, montoInicial: montoInicial);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> solicitarRetiro({required double monto, required String motivo}) async {
    final sesionId = state.sesion?.id;
    if (sesionId == null) return false;
    try {
      await _repository.solicitarRetiro(sesionCajaId: sesionId, monto: monto, motivo: motivo);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Se llama tras un cierre exitoso (ver ResumenCierreController.cerrar) —
  /// vuelve a consultar y queda en null hasta la próxima apertura.
  Future<void> refrescarTrasCierre() => cargar();
}

final sesionCajaProvider =
    StateNotifierProvider.autoDispose.family<SesionCajaController, SesionCajaState, String>((ref, cajaId) {
  return SesionCajaController(ref.watch(cashRepositoryProvider), cajaId);
});

class RetirosPendientesState {
  const RetirosPendientesState({this.pendientes = const [], this.cargando = false, this.error, this.procesando = const {}});

  final List<RetiroCajaPendiente> pendientes;
  final bool cargando;
  final String? error;

  /// RetiroIds con un autorizar/rechazar en curso — para deshabilitar solo
  /// los botones de esa fila, no la pantalla completa.
  final Set<String> procesando;

  RetirosPendientesState copyWith({
    List<RetiroCajaPendiente>? pendientes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    Set<String>? procesando,
  }) {
    return RetirosPendientesState(
      pendientes: pendientes ?? this.pendientes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      procesando: procesando ?? this.procesando,
    );
  }
}

/// Cola de trabajo de quien autoriza Retiros de Caja (permiso
/// "cash.retiros.autorizar") — mismo patrón que
/// SolicitudesCreditoPendientesController.
class RetirosPendientesController extends StateNotifier<RetirosPendientesState> {
  RetirosPendientesController(this._repository) : super(const RetirosPendientesState()) {
    cargar();
  }

  final CashRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final pendientes = await _repository.listarRetirosPendientes();
      state = state.copyWith(pendientes: pendientes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> autorizar(String retiroId) async {
    state = state.copyWith(procesando: {...state.procesando, retiroId}, limpiarError: true);
    try {
      await _repository.autorizarRetiro(retiroId);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(retiroId));
    }
  }

  Future<void> rechazar(String retiroId, String motivo) async {
    state = state.copyWith(procesando: {...state.procesando, retiroId}, limpiarError: true);
    try {
      await _repository.rechazarRetiro(retiroId: retiroId, motivo: motivo);
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString(), procesando: {...state.procesando}..remove(retiroId));
    }
  }
}

final retirosPendientesProvider = StateNotifierProvider.autoDispose<RetirosPendientesController, RetirosPendientesState>((ref) {
  return RetirosPendientesController(ref.watch(cashRepositoryProvider));
});

class ResumenCierreState {
  const ResumenCierreState({this.resumen, this.cargando = true, this.error, this.cerrando = false});

  final ResumenCierreCaja? resumen;
  final bool cargando;
  final String? error;
  final bool cerrando;

  ResumenCierreState copyWith({
    ResumenCierreCaja? resumen,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    bool? cerrando,
  }) {
    return ResumenCierreState(
      resumen: resumen ?? this.resumen,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      cerrando: cerrando ?? this.cerrando,
    );
  }
}

/// Resumen de cierre de una Sesión de Caja puntual — preview en vivo si aún
/// está Abierta, historial congelado una vez Cerrada.
class ResumenCierreController extends StateNotifier<ResumenCierreState> {
  ResumenCierreController(this._repository, this._sesionCajaId) : super(const ResumenCierreState()) {
    cargar();
  }

  final CashRepository _repository;
  final String _sesionCajaId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final resumen = await _repository.obtenerResumenCierre(_sesionCajaId);
      state = state.copyWith(resumen: resumen, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> cerrar(double montoContado) async {
    state = state.copyWith(cerrando: true, limpiarError: true);
    try {
      await _repository.cerrarCaja(sesionCajaId: _sesionCajaId, montoContado: montoContado);
      await cargar();
      state = state.copyWith(cerrando: false);
      return true;
    } catch (e) {
      state = state.copyWith(cerrando: false, error: e.toString());
      return false;
    }
  }
}

final resumenCierreProvider =
    StateNotifierProvider.autoDispose.family<ResumenCierreController, ResumenCierreState, String>((ref, sesionCajaId) {
  return ResumenCierreController(ref.watch(cashRepositoryProvider), sesionCajaId);
});
