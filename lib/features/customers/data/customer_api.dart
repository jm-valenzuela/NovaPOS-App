import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/cliente_resumen.dart';

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
    int plazoPagoDias = 0,
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
        'plazoPagoDias': plazoPagoDias,
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
    int plazoPagoDias = 0,
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
        'plazoPagoDias': plazoPagoDias,
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
}
