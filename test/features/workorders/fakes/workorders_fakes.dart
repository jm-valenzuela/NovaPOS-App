import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/domain/workorders_repository.dart';

class FakeWorkOrdersRepository implements WorkOrdersRepository {
  String? errorAforzar;
  String ordenTrabajoIdARetornar = 'ot-fake-id';
  String itemIdARetornar = 'item-fake-id';
  List<OrdenTrabajoResumen> ordenesARetornar = [];
  List<OrdenTrabajoResumen> historialARetornar = [];
  OrdenTrabajoDetalle? detalleARetornar;
  List<UsuarioResumen> usuariosARetornar = [];
  List<RolResumen> rolesARetornar = [];
  List<OperarioConCarga> cargaARetornar = [];
  String usuarioIdARetornar = 'usuario-fake-id';

  String? ultimoCajaId;
  String? ultimoClienteId;
  String? ultimaDescripcion;
  List<LineaItemOrdenTrabajoInput>? ultimasLineas;
  String? ultimoItemId;
  String? ultimoMotivoRechazo;
  String? ultimaObservacion;
  String? ultimoUsuarioIdAsignado;
  String? ultimaVentaIdEntregada;
  String? ultimaOrdenDuplicadaId;
  bool ultimoIncluirInactivos = false;
  String? ultimoNombreOperario;
  String? ultimoEmailOperario;
  String? ultimoPasswordOperario;
  String? ultimoRolIdOperario;
  String? ultimoUsuarioIdDesactivado;

  @override
  Future<String> recibir({required String cajaId, required String clienteId, required String descripcion}) async {
    ultimoCajaId = cajaId;
    ultimoClienteId = clienteId;
    ultimaDescripcion = descripcion;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ordenTrabajoIdARetornar;
  }

  @override
  Future<List<OrdenTrabajoResumen>> listar({EstadoOrdenTrabajo? estado}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return estado == null ? ordenesARetornar : ordenesARetornar.where((o) => o.estado == estado).toList();
  }

  @override
  Future<List<OrdenTrabajoResumen>> listarHistorial(String clienteId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return historialARetornar;
  }

  @override
  Future<OrdenTrabajoDetalle> obtener(String ordenTrabajoId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return detalleARetornar!;
  }

  @override
  Future<String> duplicar(String ordenTrabajoOrigenId) async {
    ultimaOrdenDuplicadaId = ordenTrabajoOrigenId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ordenTrabajoIdARetornar;
  }

  @override
  Future<String> agregarItem({required String ordenTrabajoId, required String descripcion, List<LineaItemOrdenTrabajoInput>? lineas}) async {
    ultimaDescripcion = descripcion;
    ultimasLineas = lineas;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return itemIdARetornar;
  }

  @override
  Future<void> cotizarItem({required String ordenTrabajoId, required String itemId, required List<LineaItemOrdenTrabajoInput> lineas}) async {
    ultimoItemId = itemId;
    ultimasLineas = lineas;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> aprobarItem({required String ordenTrabajoId, required String itemId}) async {
    ultimoItemId = itemId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> rechazarItem({required String ordenTrabajoId, required String itemId, String? motivo}) async {
    ultimoItemId = itemId;
    ultimoMotivoRechazo = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> iniciarTrabajoItem({required String ordenTrabajoId, required String itemId}) async {
    ultimoItemId = itemId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> terminarItem({required String ordenTrabajoId, required String itemId}) async {
    ultimoItemId = itemId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> editarObservacionItem({required String ordenTrabajoId, required String itemId, String? observacion}) async {
    ultimoItemId = itemId;
    ultimaObservacion = observacion;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> asignarOperadorItem({required String ordenTrabajoId, required String itemId, String? usuarioId}) async {
    ultimoItemId = itemId;
    ultimoUsuarioIdAsignado = usuarioId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> entregar({required String ordenTrabajoId, required String ventaId}) async {
    ultimaVentaIdEntregada = ventaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<List<UsuarioResumen>> listarUsuarios({bool incluirInactivos = false}) async {
    ultimoIncluirInactivos = incluirInactivos;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return usuariosARetornar;
  }

  @override
  Future<String> crearUsuario({required String nombreCompleto, required String email, required String password, required String rolId}) async {
    ultimoNombreOperario = nombreCompleto;
    ultimoEmailOperario = email;
    ultimoPasswordOperario = password;
    ultimoRolIdOperario = rolId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return usuarioIdARetornar;
  }

  @override
  Future<void> desactivarUsuario(String usuarioId) async {
    ultimoUsuarioIdDesactivado = usuarioId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<List<RolResumen>> listarRoles() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return rolesARetornar;
  }

  @override
  Future<List<OperarioConCarga>> listarCargaOperarios() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return cargaARetornar;
  }
}
