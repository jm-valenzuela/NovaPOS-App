import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/flujo_caja_dia.dart';

class ReportingApi {
  ReportingApi(this._client);

  final ApiClient _client;

  Future<List<FlujoCajaDia>> obtenerFlujoCaja({required DateTime desde, required DateTime hasta}) async {
    try {
      final respuesta = await _client.dio.get('/reportes/flujo-caja', queryParameters: {
        'desde': _formatearFecha(desde),
        'hasta': _formatearFecha(hasta),
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => FlujoCajaDia.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  static String _formatearFecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
}
