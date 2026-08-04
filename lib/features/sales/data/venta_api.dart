import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/resumen_venta.dart';
import '../domain/models/venta_enums.dart';

class VentaApi {
  VentaApi(this._client);

  final ApiClient _client;

  Future<String> crear({
    required String cajaId,
    String? clienteId,
    FormaPago formaPago = FormaPago.contado,
    TipoEntrega tipoEntrega = TipoEntrega.inmediata,
  }) async {
    try {
      final respuesta = await _client.dio.post('/ventas', data: {
        'cajaId': cajaId,
        'clienteId': clienteId,
        'formaPago': formaPago.valorApi,
        'tipoEntrega': tipoEntrega.valorApi,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> agregarLinea({
    required String ventaId,
    required String varianteProductoId,
    required double cantidad,
  }) async {
    try {
      await _client.dio.post('/ventas/$ventaId/lineas', data: {
        'varianteProductoId': varianteProductoId,
        'cantidad': cantidad,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<ResumenVenta> confirmar(String ventaId) async {
    try {
      final respuesta = await _client.dio.post('/ventas/$ventaId/confirmar');
      return ResumenVenta.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
