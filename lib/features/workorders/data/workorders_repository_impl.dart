import '../domain/models/orden_trabajo.dart';
import '../domain/workorders_repository.dart';
import 'workorders_api.dart';

class WorkOrdersRepositoryImpl implements WorkOrdersRepository {
  WorkOrdersRepositoryImpl(this._api);

  final WorkOrdersApi _api;

  @override
  Future<String> recibir({required String cajaId, required String clienteId, required String descripcion}) =>
      _api.recibir(cajaId: cajaId, clienteId: clienteId, descripcion: descripcion);

  @override
  Future<List<OrdenTrabajoResumen>> listar({EstadoOrdenTrabajo? estado}) => _api.listar(estado: estado);

  @override
  Future<List<OrdenTrabajoResumen>> listarHistorial(String clienteId) => _api.listarHistorial(clienteId);

  @override
  Future<OrdenTrabajoDetalle> obtener(String ordenTrabajoId) => _api.obtener(ordenTrabajoId);

  @override
  Future<String> duplicar(String ordenTrabajoOrigenId) => _api.duplicar(ordenTrabajoOrigenId);

  @override
  Future<String> agregarItem({required String ordenTrabajoId, required String descripcion, List<LineaItemOrdenTrabajoInput>? lineas}) =>
      _api.agregarItem(ordenTrabajoId: ordenTrabajoId, descripcion: descripcion, lineas: lineas);

  @override
  Future<void> cotizarItem({required String ordenTrabajoId, required String itemId, required List<LineaItemOrdenTrabajoInput> lineas}) =>
      _api.cotizarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, lineas: lineas);

  @override
  Future<void> aprobarItem({required String ordenTrabajoId, required String itemId}) =>
      _api.aprobarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);

  @override
  Future<void> rechazarItem({required String ordenTrabajoId, required String itemId, String? motivo}) =>
      _api.rechazarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, motivo: motivo);

  @override
  Future<void> iniciarTrabajoItem({required String ordenTrabajoId, required String itemId}) =>
      _api.iniciarTrabajoItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);

  @override
  Future<void> terminarItem({required String ordenTrabajoId, required String itemId}) =>
      _api.terminarItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId);

  @override
  Future<void> editarObservacionItem({required String ordenTrabajoId, required String itemId, String? observacion}) =>
      _api.editarObservacionItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, observacion: observacion);

  @override
  Future<void> asignarOperadorItem({required String ordenTrabajoId, required String itemId, String? usuarioId}) =>
      _api.asignarOperadorItem(ordenTrabajoId: ordenTrabajoId, itemId: itemId, usuarioId: usuarioId);

  @override
  Future<void> entregar({required String ordenTrabajoId, required String ventaId}) =>
      _api.entregar(ordenTrabajoId: ordenTrabajoId, ventaId: ventaId);

  @override
  Future<String> registrarAnticipo({
    required String ordenTrabajoId,
    required String sesionCajaId,
    required double monto,
    required MedioPagoAnticipo medioPago,
  }) =>
      _api.registrarAnticipo(ordenTrabajoId: ordenTrabajoId, sesionCajaId: sesionCajaId, monto: monto, medioPago: medioPago);

  @override
  Future<List<UsuarioResumen>> listarUsuarios({bool incluirInactivos = false}) =>
      _api.listarUsuarios(incluirInactivos: incluirInactivos);

  @override
  Future<String> crearUsuario({required String nombreCompleto, required String email, required String password, required String rolId}) =>
      _api.crearUsuario(nombreCompleto: nombreCompleto, email: email, password: password, rolId: rolId);

  @override
  Future<void> desactivarUsuario(String usuarioId) => _api.desactivarUsuario(usuarioId);

  @override
  Future<List<RolResumen>> listarRoles() => _api.listarRoles();

  @override
  Future<List<OperarioConCarga>> listarCargaOperarios() => _api.listarCargaOperarios();
}
