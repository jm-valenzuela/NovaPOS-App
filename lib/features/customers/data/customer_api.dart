import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/cliente_resumen.dart';
import '../domain/models/plazo_pago.dart';
import '../domain/models/solicitud_credito_pendiente.dart';

class CustomerApi {
  CustomerApi(this._client);

  final ApiClient _client;

  Future<List<ClienteResumen>> buscarClientes({String? texto}) async {
    try {
      final respuesta = await _client.dio.get('/clientes/buscar', queryParameters: {
        if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => ClienteResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearCliente({
    required String nombre,
    String? rut,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    try {
      final respuesta = await _client.dio.post('/clientes', data: {
        'nombre': nombre,
        'rut': rut,
        'email': email,
        'telefono': telefono,
        'cupoCredito': cupoCredito,
        'plazoPagoId': plazoPagoId,
        'giro': giro,
        'direccion': direccion,
        'comuna': comuna,
        'ciudad': ciudad,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> actualizarCliente({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) async {
    try {
      await _client.dio.put('/clientes/$clienteId', data: {
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'cupoCredito': cupoCredito,
        'plazoPagoId': plazoPagoId,
        'giro': giro,
        'direccion': direccion,
        'comuna': comuna,
        'ciudad': ciudad,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> asignarRutCliente({required String clienteId, required String rut}) async {
    try {
      await _client.dio.put('/clientes/$clienteId/rut', data: {'rut': rut});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> solicitarCreditoCliente({
    required String clienteId,
    required double cupoSolicitado,
    String? plazoPagoIdSolicitado,
  }) async {
    try {
      await _client.dio.post('/clientes/$clienteId/credito/solicitar', data: {
        'cupoSolicitado': cupoSolicitado,
        'plazoPagoIdSolicitado': plazoPagoIdSolicitado,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> autorizarCreditoCliente(String clienteId) async {
    try {
      await _client.dio.post('/clientes/$clienteId/credito/autorizar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> rechazarCreditoCliente({required String clienteId, required String motivo}) async {
    try {
      await _client.dio.post('/clientes/$clienteId/credito/rechazar', data: {'motivo': motivo});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<SolicitudCreditoPendiente>> listarSolicitudesCreditoPendientes() async {
    try {
      final respuesta = await _client.dio.get('/clientes/credito/pendientes');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => SolicitudCreditoPendiente.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas}) async {
    try {
      final respuesta = await _client.dio.post('/clientes/plazos-pago', data: {
        'nombre': nombre,
        'diasCuotas': diasCuotas,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<PlazoPago>> listarPlazosPago() async {
    try {
      final respuesta = await _client.dio.get('/clientes/plazos-pago');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => PlazoPago.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> activarPlazoPago(String plazoPagoId) async {
    try {
      await _client.dio.post('/clientes/plazos-pago/$plazoPagoId/activar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> desactivarPlazoPago(String plazoPagoId) async {
    try {
      await _client.dio.post('/clientes/plazos-pago/$plazoPagoId/desactivar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
