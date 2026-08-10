import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/bodega_resumen.dart';
import '../domain/models/bodega_venta.dart';
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

  /// Null si la Sucursal no tiene una Bodega de venta configurada (404).
  Future<BodegaVenta?> obtenerBodegaVenta(String sucursalId) async {
    try {
      final respuesta = await _client.dio.get('/bodegas/venta', queryParameters: {'sucursalId': sucursalId});
      return BodegaVenta.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      ApiClient.lanzarError(e);
    }
  }

  Future<List<BodegaResumen>> listarBodegas() async {
    try {
      final respuesta = await _client.dio.get('/bodegas');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => BodegaResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
