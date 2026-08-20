import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../sales/domain/models/venta_detalle.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show salesRepositoryProvider;
import '../../data/workorders_api.dart';
import '../../data/workorders_repository_impl.dart';
import '../../domain/models/orden_trabajo.dart';
import '../../domain/workorders_repository.dart';

final workOrdersApiProvider = Provider<WorkOrdersApi>((ref) => WorkOrdersApi(ref.watch(apiClientProvider)));

final workOrdersRepositoryProvider =
    Provider<WorkOrdersRepository>((ref) => WorkOrdersRepositoryImpl(ref.watch(workOrdersApiProvider)));

/// Para el selector de "Asignar Operador" en cada Ítem — solo Usuarios activos.
final usuariosProvider = FutureProvider.autoDispose<List<UsuarioResumen>>((ref) {
  return ref.watch(workOrdersRepositoryProvider).listarUsuarios();
});

/// Para el selector de Rol al crear un Operario.
final rolesProvider = FutureProvider.autoDispose<List<RolResumen>>((ref) {
  return ref.watch(workOrdersRepositoryProvider).listarRoles();
});

/// "Revisar lo asignado" — qué Ítems abiertos tiene cada Operario ahora mismo.
final cargaOperariosProvider = FutureProvider.autoDispose<List<OperarioConCarga>>((ref) {
  return ref.watch(workOrdersRepositoryProvider).listarCargaOperarios();
});

class OperariosState {
  const OperariosState({this.operarios = const [], this.cargando = false, this.error});

  final List<UsuarioResumen> operarios;
  final bool cargando;
  final String? error;

  OperariosState copyWith({List<UsuarioResumen>? operarios, bool? cargando, String? error, bool limpiarError = false}) {
    return OperariosState(
      operarios: operarios ?? this.operarios,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Gestión de Operarios (Usuarios) — listado con inactivos, alta y baja.
class OperariosController extends StateNotifier<OperariosState> {
  OperariosController(this._repository) : super(const OperariosState()) {
    cargar();
  }

  final WorkOrdersRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final operarios = await _repository.listarUsuarios(incluirInactivos: true);
      state = state.copyWith(operarios: operarios, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> crear({required String nombreCompleto, required String email, required String password, required String rolId}) async {
    try {
      await _repository.crearUsuario(nombreCompleto: nombreCompleto, email: email, password: password, rolId: rolId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> desactivar(String usuarioId) async {
    try {
      await _repository.desactivarUsuario(usuarioId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final operariosProvider = StateNotifierProvider.autoDispose<OperariosController, OperariosState>((ref) {
  return OperariosController(ref.watch(workOrdersRepositoryProvider));
});

class OrdenesTrabajoState {
  const OrdenesTrabajoState({this.ordenes = const [], this.cargando = false, this.error, this.filtroEstado});

  final List<OrdenTrabajoResumen> ordenes;
  final bool cargando;
  final String? error;
  final EstadoOrdenTrabajo? filtroEstado;

  OrdenesTrabajoState copyWith({
    List<OrdenTrabajoResumen>? ordenes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    EstadoOrdenTrabajo? filtroEstado,
    bool limpiarFiltro = false,
  }) {
    return OrdenesTrabajoState(
      ordenes: ordenes ?? this.ordenes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      filtroEstado: limpiarFiltro ? null : (filtroEstado ?? this.filtroEstado),
    );
  }
}

/// Listado de Órdenes de Trabajo con filtro opcional por Estado — la
/// creación (Recibir) y el resto del flujo viven en
/// OrdenTrabajoDetalleController, este controller solo sostiene la lista.
class OrdenesTrabajoController extends StateNotifier<OrdenesTrabajoState> {
  OrdenesTrabajoController(this._repository) : super(const OrdenesTrabajoState()) {
    cargar();
  }

  final WorkOrdersRepository _repository;

  Future<void> cargar({EstadoOrdenTrabajo? filtroEstado, bool limpiarFiltro = false}) async {
    state = state.copyWith(cargando: true, limpiarError: true, filtroEstado: filtroEstado, limpiarFiltro: limpiarFiltro);
    try {
      final ordenes = await _repository.listar(estado: state.filtroEstado);
      state = state.copyWith(ordenes: ordenes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final ordenesTrabajoProvider = StateNotifierProvider.autoDispose<OrdenesTrabajoController, OrdenesTrabajoState>((ref) {
  return OrdenesTrabajoController(ref.watch(workOrdersRepositoryProvider));
});

class HistorialClienteState {
  const HistorialClienteState({this.ordenes = const [], this.cargando = false, this.error});

  final List<OrdenTrabajoResumen> ordenes;
  final bool cargando;
  final String? error;

  HistorialClienteState copyWith({List<OrdenTrabajoResumen>? ordenes, bool? cargando, String? error, bool limpiarError = false}) {
    return HistorialClienteState(
      ordenes: ordenes ?? this.ordenes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Historial de Órdenes de Trabajo de un Cliente — para elegir una Orden
/// anterior y Duplicarla (ver DuplicarOrdenTrabajoDialog/acción).
class HistorialClienteController extends StateNotifier<HistorialClienteState> {
  HistorialClienteController(this._repository, this.clienteId) : super(const HistorialClienteState()) {
    cargar();
  }

  final WorkOrdersRepository _repository;
  final String clienteId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final ordenes = await _repository.listarHistorial(clienteId);
      state = state.copyWith(ordenes: ordenes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  /// Retorna el Id de la nueva Orden duplicada, o null si falló (el error queda en el estado).
  Future<String?> duplicar(String ordenTrabajoOrigenId) async {
    try {
      return await _repository.duplicar(ordenTrabajoOrigenId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final historialClienteProvider =
    StateNotifierProvider.autoDispose.family<HistorialClienteController, HistorialClienteState, String>((ref, clienteId) {
  return HistorialClienteController(ref.watch(workOrdersRepositoryProvider), clienteId);
});

class OrdenTrabajoDetalleState {
  const OrdenTrabajoDetalleState({this.orden, this.cargando = false, this.error});

  final OrdenTrabajoDetalle? orden;
  final bool cargando;
  final String? error;

  OrdenTrabajoDetalleState copyWith({OrdenTrabajoDetalle? orden, bool? cargando, String? error, bool limpiarError = false}) {
    return OrdenTrabajoDetalleState(
      orden: orden ?? this.orden,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Detalle de una Orden puntual — cada acción sobre un Ítem recarga el
/// detalle completo después, mismo criterio que OrdenCompraDetalleController.
class OrdenTrabajoDetalleController extends StateNotifier<OrdenTrabajoDetalleState> {
  OrdenTrabajoDetalleController(this._repository, this.ordenTrabajoId) : super(const OrdenTrabajoDetalleState()) {
    cargar();
  }

  final WorkOrdersRepository _repository;
  final String ordenTrabajoId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final orden = await _repository.obtener(ordenTrabajoId);
      state = state.copyWith(orden: orden, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> agregarItem({required String descripcion, List<LineaItemOrdenTrabajoInput>? lineas}) async {
    try {
      await _repository.agregarItem(ordenTrabajoId: ordenTrabajoId, descripcion: descripcion, lineas: lineas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cotizarItem({required String itemId, required List<LineaItemOrdenTrabajoInput> lineas}) async {
    try {
      await _repository.cotizarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, lineas: lineas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> aprobarItem(String itemId) async {
    try {
      await _repository.aprobarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rechazarItem({required String itemId, String? motivo}) async {
    try {
      await _repository.rechazarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, motivo: motivo);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> iniciarTrabajoItem(String itemId) async {
    try {
      await _repository.iniciarTrabajoItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> terminarItem(String itemId) async {
    try {
      await _repository.terminarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> editarObservacionItem({required String itemId, String? observacion}) async {
    try {
      await _repository.editarObservacionItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, observacion: observacion);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> asignarOperadorItem({required String itemId, String? usuarioId}) async {
    try {
      await _repository.asignarOperadorItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, usuarioId: usuarioId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> entregar(String ventaId) async {
    try {
      await _repository.entregar(ordenTrabajoId: ordenTrabajoId, ventaId: ventaId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final ordenTrabajoDetalleProvider =
    StateNotifierProvider.autoDispose.family<OrdenTrabajoDetalleController, OrdenTrabajoDetalleState, String>((ref, ordenTrabajoId) {
  return OrdenTrabajoDetalleController(ref.watch(workOrdersRepositoryProvider), ordenTrabajoId);
});

/// Detalle de la Venta vinculada a la Orden (ver OrdenTrabajoDetalle.ventaId) — con los datos del DTE (Boleta/Factura) emitido, para mostrarlos y ofrecer reimprimir.
final ventaVinculadaProvider = FutureProvider.autoDispose.family<VentaDetalle, String>((ref, ventaId) {
  return ref.watch(salesRepositoryProvider).obtenerVenta(ventaId);
});
