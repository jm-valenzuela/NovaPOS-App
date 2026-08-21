import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/orden_trabajo.dart';

class WorkOrdersApi {
  WorkOrdersApi(this._client);

  final ApiClient _client;

  Future<String> recibir({required String cajaId, required String clienteId, required String descripcion}) async {
    try {
      final respuesta = await _client.dio.post('/ordenes-trabajo', data: {
        'cajaId': cajaId,
        'clienteId': clienteId,
        'descripcion': descripcion,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<OrdenTrabajoResumen>> listar({EstadoOrdenTrabajo? estado}) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo', queryParameters: {
        if (estado != null) 'estado': estado.valorApi,
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => OrdenTrabajoResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Historial de un Cliente — para elegir una Orden anterior y Duplicarla.
  Future<List<OrdenTrabajoResumen>> listarHistorial(String clienteId) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo/historial', queryParameters: {'clienteId': clienteId});
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => OrdenTrabajoResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<OrdenTrabajoDetalle> obtener(String ordenTrabajoId) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo/$ordenTrabajoId');
      return OrdenTrabajoDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> duplicar(String ordenTrabajoOrigenId) async {
    try {
      final respuesta = await _client.dio.post('/ordenes-trabajo/$ordenTrabajoOrigenId/duplicado');
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Sin líneas, el Ítem nace Pendiente de evaluación. Con líneas, nace Cotizado directo.
  Future<String> agregarItem({
    required String ordenTrabajoId,
    required String descripcion,
    List<LineaItemOrdenTrabajoInput>? lineas,
  }) async {
    try {
      final respuesta = await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items', data: {
        'descripcion': descripcion,
        'lineas': lineas?.map((l) => l.toJson()).toList(),
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> cotizarItem({
    required String ordenTrabajoId,
    required String itemId,
    required List<LineaItemOrdenTrabajoInput> lineas,
  }) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/cotizacion', data: {
        'lineas': lineas.map((l) => l.toJson()).toList(),
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> aprobarItem({required String ordenTrabajoId, required String itemId}) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/aprobacion');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> rechazarItem({required String ordenTrabajoId, required String itemId, String? motivo}) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/rechazo', data: {'motivo': motivo});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> iniciarTrabajoItem({required String ordenTrabajoId, required String itemId}) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/inicio-trabajo');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> terminarItem({required String ordenTrabajoId, required String itemId}) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/termino');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> editarObservacionItem({required String ordenTrabajoId, required String itemId, String? observacion}) async {
    try {
      await _client.dio.put('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/observacion', data: {'observacion': observacion});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> asignarOperadorItem({required String ordenTrabajoId, required String itemId, String? usuarioId}) async {
    try {
      await _client.dio.put('/ordenes-trabajo/$ordenTrabajoId/items/$itemId/operador', data: {'usuarioId': usuarioId});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> entregar({required String ordenTrabajoId, required String ventaId}) async {
    try {
      await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/entrega', data: {'ventaId': ventaId});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> registrarAnticipo({
    required String ordenTrabajoId,
    required String sesionCajaId,
    required double monto,
    required MedioPagoAnticipo medioPago,
  }) async {
    try {
      final respuesta = await _client.dio.post('/ordenes-trabajo/$ordenTrabajoId/anticipos', data: {
        'sesionCajaId': sesionCajaId,
        'monto': monto,
        'medioPago': medioPago.valorApi,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Solo Usuarios cuyo Rol puede gestionar Órdenes de Trabajo (ver
  /// ListarOperariosQuery en el backend) — sin incluirInactivos, solo los
  /// activos (selector de "Asignar Operador"); con incluirInactivos=true
  /// trae también los desactivados (pantalla de administración de Operarios).
  Future<List<UsuarioResumen>> listarUsuarios({bool incluirInactivos = false}) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo/operarios', queryParameters: {'incluirInactivos': incluirInactivos});
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => UsuarioResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
    required String rolId,
  }) async {
    try {
      final respuesta = await _client.dio.post('/usuarios', data: {
        'nombreCompleto': nombreCompleto,
        'email': email,
        'password': password,
        'rolId': rolId,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> desactivarUsuario(String usuarioId) async {
    try {
      await _client.dio.post('/usuarios/$usuarioId/desactivacion');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Solo los Roles que pueden gestionar Órdenes de Trabajo — para el selector de Rol al crear un Operario.
  Future<List<RolResumen>> listarRoles() async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo/operarios/roles');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => RolResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// "Revisar lo asignado" — qué Ítems abiertos tiene cada Operario ahora mismo.
  Future<List<OperarioConCarga>> listarCargaOperarios() async {
    try {
      final respuesta = await _client.dio.get('/ordenes-trabajo/operarios/carga');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => OperarioConCarga.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
