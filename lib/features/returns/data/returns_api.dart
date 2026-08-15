import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/linea_devolucion_input.dart';
import '../domain/models/nota_credito_cliente_resumen.dart';
import '../domain/models/nota_credito_disponible_resumen.dart';
import '../domain/models/venta_confirmada_resumen.dart';
import '../domain/models/venta_para_devolucion_detalle.dart';

class ReturnsApi {
  ReturnsApi(this._client);

  final ApiClient _client;

  Future<List<VentaConfirmadaResumen>> listarVentasConfirmadas(String sucursalId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/confirmadas', queryParameters: {'sucursalId': sucursalId});
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => VentaConfirmadaResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<VentaParaDevolucionDetalle> obtenerVentaParaDevolucion(String ventaId) async {
    try {
      final respuesta = await _client.dio.get('/devoluciones/venta/$ventaId');
      return VentaParaDevolucionDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> registrarDevolucion({
    required String ventaOrigenId,
    required String clienteId,
    required List<LineaDevolucionInput> lineas,
    required String motivo,
    required bool reembolsarEnEfectivo,
    String? sesionCajaId,
  }) async {
    try {
      final respuesta = await _client.dio.post('/devoluciones', data: {
        'ventaOrigenId': ventaOrigenId,
        'clienteId': clienteId,
        'lineas': lineas.map((l) => l.toJson()).toList(),
        'motivo': motivo,
        'reembolsarEnEfectivo': reembolsarEnEfectivo,
        'sesionCajaId': sesionCajaId,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<NotaCreditoClienteResumen>> listarNotasCreditoCliente(String clienteId, {bool soloDisponibles = false}) async {
    try {
      final respuesta = await _client.dio.get(
        '/devoluciones/clientes/$clienteId/notas-credito',
        queryParameters: {'soloDisponibles': soloDisponibles},
      );
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => NotaCreditoClienteResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<NotaCreditoDisponibleResumen>> listarNotasCreditoDisponibles() async {
    try {
      final respuesta = await _client.dio.get('/devoluciones/notas-credito/disponibles');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => NotaCreditoDisponibleResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> reembolsarNotaCredito({required String notaCreditoId, required String sesionCajaId}) async {
    try {
      await _client.dio.post('/devoluciones/notas-credito/$notaCreditoId/reembolsar', data: {'sesionCajaId': sesionCajaId});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
