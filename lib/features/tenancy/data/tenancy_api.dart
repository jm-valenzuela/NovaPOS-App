import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/caja_resumen.dart';

class TenancyApi {
  TenancyApi(this._client);

  final ApiClient _client;

  Future<List<CajaResumen>> listarCajas() async {
    try {
      final respuesta = await _client.dio.get('/cajas');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => CajaResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
