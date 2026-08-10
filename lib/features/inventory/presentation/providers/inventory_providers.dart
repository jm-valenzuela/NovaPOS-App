import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sales/presentation/providers/pos_providers.dart' show inventoryRepositoryProvider, tenancyRepositoryProvider;
import '../../../tenancy/domain/models/bodega_resumen.dart';
import '../../domain/inventory_repository.dart';
import '../../domain/models/inventory_enums.dart';
import '../../domain/models/tarjeta_existencia.dart';
import '../../domain/models/toma_inventario.dart';
import '../../domain/models/traslado_inventario.dart';

/// Todas las Bodegas de la Empresa — se piden una sola vez por sesión de
/// las pantallas de Inventario, se recargan solo si algo falló (ver `retry`
/// del propio FutureProvider en la UI que lo consuma).
final bodegasInventarioProvider = FutureProvider<List<BodegaResumen>>((ref) {
  return ref.watch(tenancyRepositoryProvider).listarBodegas();
});

// ---------------------------------------------------------------------------
// Ajustes de Inventario (Tomas)
// ---------------------------------------------------------------------------

class TomasInventarioState {
  const TomasInventarioState({this.tomas = const [], this.cargando = false, this.error, this.filtroBodegaId, this.filtroEstado});

  final List<TomaInventarioListado> tomas;
  final bool cargando;
  final String? error;
  final String? filtroBodegaId;
  final EstadoTomaInventario? filtroEstado;

  TomasInventarioState copyWith({
    List<TomaInventarioListado>? tomas,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    String? filtroBodegaId,
    bool limpiarFiltroBodega = false,
    EstadoTomaInventario? filtroEstado,
    bool limpiarFiltroEstado = false,
  }) {
    return TomasInventarioState(
      tomas: tomas ?? this.tomas,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      filtroBodegaId: limpiarFiltroBodega ? null : (filtroBodegaId ?? this.filtroBodegaId),
      filtroEstado: limpiarFiltroEstado ? null : (filtroEstado ?? this.filtroEstado),
    );
  }
}

/// Listado de Tomas con filtros opcionales por Bodega y Estado — abrir una
/// nueva Toma vive fuera de este controller (ver NuevaTomaDialog), que solo
/// necesita el Id devuelto para navegar al detalle.
class TomasInventarioController extends StateNotifier<TomasInventarioState> {
  TomasInventarioController(this._repository) : super(const TomasInventarioState()) {
    cargar();
  }

  final InventoryRepository _repository;

  Future<void> cargar({String? filtroBodegaId, bool limpiarFiltroBodega = false, EstadoTomaInventario? filtroEstado, bool limpiarFiltroEstado = false}) async {
    state = state.copyWith(
      cargando: true,
      limpiarError: true,
      filtroBodegaId: filtroBodegaId,
      limpiarFiltroBodega: limpiarFiltroBodega,
      filtroEstado: filtroEstado,
      limpiarFiltroEstado: limpiarFiltroEstado,
    );
    try {
      final tomas = await _repository.listarTomas(bodegaId: state.filtroBodegaId, estado: state.filtroEstado);
      state = state.copyWith(tomas: tomas, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final tomasInventarioProvider = StateNotifierProvider.autoDispose<TomasInventarioController, TomasInventarioState>((ref) {
  return TomasInventarioController(ref.watch(inventoryRepositoryProvider));
});

class TomaInventarioDetalleState {
  const TomaInventarioDetalleState({this.toma, this.cargando = false, this.error, this.cerrada = false});

  final TomaInventarioDetalle? toma;
  final bool cargando;
  final String? error;

  /// true recién después de un cierre exitoso — la pantalla lo usa para
  /// mostrar el resultado antes de volver al listado.
  final bool cerrada;

  TomaInventarioDetalleState copyWith({TomaInventarioDetalle? toma, bool? cargando, String? error, bool limpiarError = false, bool? cerrada}) {
    return TomaInventarioDetalleState(
      toma: toma ?? this.toma,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      cerrada: cerrada ?? this.cerrada,
    );
  }
}

/// Detalle de una Toma puntual — registrar conteo siempre recarga el
/// detalle completo después, para reflejar la Diferencia real que calculó
/// el servidor (CantidadSistema es un snapshot tomado en ese momento).
class TomaInventarioDetalleController extends StateNotifier<TomaInventarioDetalleState> {
  TomaInventarioDetalleController(this._repository, this.tomaId) : super(const TomaInventarioDetalleState()) {
    cargar();
  }

  final InventoryRepository _repository;
  final String tomaId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final toma = await _repository.obtenerToma(tomaId);
      state = state.copyWith(toma: toma, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> registrarConteo({required String varianteProductoId, required double cantidadContada}) async {
    try {
      await _repository.registrarConteo(tomaId: tomaId, varianteProductoId: varianteProductoId, cantidadContada: cantidadContada);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cerrar() async {
    try {
      await _repository.cerrarToma(tomaId);
      await cargar();
      state = state.copyWith(cerrada: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final tomaInventarioDetalleProvider =
    StateNotifierProvider.autoDispose.family<TomaInventarioDetalleController, TomaInventarioDetalleState, String>((ref, tomaId) {
  return TomaInventarioDetalleController(ref.watch(inventoryRepositoryProvider), tomaId);
});

// ---------------------------------------------------------------------------
// Traslados
// ---------------------------------------------------------------------------

class TrasladosState {
  const TrasladosState({this.traslados = const [], this.cargando = false, this.error, this.filtroBodegaId, this.filtroEstado});

  final List<TrasladoListado> traslados;
  final bool cargando;
  final String? error;
  final String? filtroBodegaId;
  final EstadoTraslado? filtroEstado;

  TrasladosState copyWith({
    List<TrasladoListado>? traslados,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    String? filtroBodegaId,
    bool limpiarFiltroBodega = false,
    EstadoTraslado? filtroEstado,
    bool limpiarFiltroEstado = false,
  }) {
    return TrasladosState(
      traslados: traslados ?? this.traslados,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      filtroBodegaId: limpiarFiltroBodega ? null : (filtroBodegaId ?? this.filtroBodegaId),
      filtroEstado: limpiarFiltroEstado ? null : (filtroEstado ?? this.filtroEstado),
    );
  }
}

class TrasladosController extends StateNotifier<TrasladosState> {
  TrasladosController(this._repository) : super(const TrasladosState()) {
    cargar();
  }

  final InventoryRepository _repository;

  Future<void> cargar({String? filtroBodegaId, bool limpiarFiltroBodega = false, EstadoTraslado? filtroEstado, bool limpiarFiltroEstado = false}) async {
    state = state.copyWith(
      cargando: true,
      limpiarError: true,
      filtroBodegaId: filtroBodegaId,
      limpiarFiltroBodega: limpiarFiltroBodega,
      filtroEstado: filtroEstado,
      limpiarFiltroEstado: limpiarFiltroEstado,
    );
    try {
      final traslados = await _repository.listarTraslados(bodegaId: state.filtroBodegaId, estado: state.filtroEstado);
      state = state.copyWith(traslados: traslados, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final trasladosProvider = StateNotifierProvider.autoDispose<TrasladosController, TrasladosState>((ref) {
  return TrasladosController(ref.watch(inventoryRepositoryProvider));
});

class TrasladoDetalleState {
  const TrasladoDetalleState({this.traslado, this.cargando = false, this.error});

  final TrasladoDetalle? traslado;
  final bool cargando;
  final String? error;

  TrasladoDetalleState copyWith({TrasladoDetalle? traslado, bool? cargando, String? error, bool limpiarError = false}) {
    return TrasladoDetalleState(
      traslado: traslado ?? this.traslado,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Detalle de un Traslado puntual — agregar línea/enviar/recibir siempre
/// recargan el detalle completo después, mismo criterio que OrdenCompraDetalleController.
class TrasladoDetalleController extends StateNotifier<TrasladoDetalleState> {
  TrasladoDetalleController(this._repository, this.trasladoId) : super(const TrasladoDetalleState()) {
    cargar();
  }

  final InventoryRepository _repository;
  final String trasladoId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final traslado = await _repository.obtenerTraslado(trasladoId);
      state = state.copyWith(traslado: traslado, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> agregarLinea({required String varianteProductoId, required double cantidad}) async {
    try {
      await _repository.agregarLineaTraslado(trasladoId: trasladoId, varianteProductoId: varianteProductoId, cantidad: cantidad);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> enviar() async {
    try {
      await _repository.enviarTraslado(trasladoId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recibir(Map<String, double> lineas) async {
    try {
      await _repository.recibirTraslado(trasladoId: trasladoId, lineas: lineas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final trasladoDetalleProvider =
    StateNotifierProvider.autoDispose.family<TrasladoDetalleController, TrasladoDetalleState, String>((ref, trasladoId) {
  return TrasladoDetalleController(ref.watch(inventoryRepositoryProvider), trasladoId);
});

// ---------------------------------------------------------------------------
// Tarjeta de Existencia (Kardex)
// ---------------------------------------------------------------------------

class KardexState {
  const KardexState({this.lineas = const [], this.cargando = false, this.error, this.consultado = false});

  final List<LineaTarjetaExistencia> lineas;
  final bool cargando;
  final String? error;

  /// false hasta la primera consulta — distingue "sin movimientos" de
  /// "todavía no se eligió Bodega/Variante".
  final bool consultado;

  KardexState copyWith({List<LineaTarjetaExistencia>? lineas, bool? cargando, String? error, bool limpiarError = false, bool? consultado}) {
    return KardexState(
      lineas: lineas ?? this.lineas,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      consultado: consultado ?? this.consultado,
    );
  }
}

class KardexController extends StateNotifier<KardexState> {
  KardexController(this._repository) : super(const KardexState());

  final InventoryRepository _repository;

  Future<void> consultar({required String bodegaId, required String varianteProductoId}) async {
    state = state.copyWith(cargando: true, limpiarError: true, consultado: true);
    try {
      final lineas = await _repository.obtenerTarjetaExistencia(bodegaId: bodegaId, varianteProductoId: varianteProductoId);
      state = state.copyWith(lineas: lineas, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final kardexProvider = StateNotifierProvider.autoDispose<KardexController, KardexState>((ref) {
  return KardexController(ref.watch(inventoryRepositoryProvider));
});
