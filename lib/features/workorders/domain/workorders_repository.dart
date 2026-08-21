import 'models/orden_trabajo.dart';

abstract class WorkOrdersRepository {
  Future<String> recibir({required String cajaId, required String clienteId, required String descripcion});

  Future<List<OrdenTrabajoResumen>> listar({EstadoOrdenTrabajo? estado});

  Future<List<OrdenTrabajoResumen>> listarHistorial(String clienteId);

  Future<OrdenTrabajoDetalle> obtener(String ordenTrabajoId);

  Future<String> duplicar(String ordenTrabajoOrigenId);

  Future<String> agregarItem({required String ordenTrabajoId, required String descripcion, List<LineaItemOrdenTrabajoInput>? lineas});

  Future<void> cotizarItem({required String ordenTrabajoId, required String itemId, required List<LineaItemOrdenTrabajoInput> lineas});

  Future<void> aprobarItem({required String ordenTrabajoId, required String itemId});

  Future<void> rechazarItem({required String ordenTrabajoId, required String itemId, String? motivo});

  Future<void> iniciarTrabajoItem({required String ordenTrabajoId, required String itemId});

  Future<void> terminarItem({required String ordenTrabajoId, required String itemId});

  Future<void> editarObservacionItem({required String ordenTrabajoId, required String itemId, String? observacion});

  Future<void> asignarOperadorItem({required String ordenTrabajoId, required String itemId, String? usuarioId});

  Future<void> entregar({required String ordenTrabajoId, required String ventaId});

  /// Dinero recibido por adelantado (ej. para comprarle a un Proveedor) — exige una Sesión de Caja Abierta.
  Future<String> registrarAnticipo({
    required String ordenTrabajoId,
    required String sesionCajaId,
    required double monto,
    required MedioPagoAnticipo medioPago,
  });

  Future<List<UsuarioResumen>> listarUsuarios({bool incluirInactivos = false});

  Future<String> crearUsuario({required String nombreCompleto, required String email, required String password, required String rolId});

  Future<void> desactivarUsuario(String usuarioId);

  Future<List<RolResumen>> listarRoles();

  Future<List<OperarioConCarga>> listarCargaOperarios();
}
