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
}
