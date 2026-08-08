import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../sales/domain/models/venta_enums.dart';
import '../domain/models/cliente_cobranza.dart';
import '../domain/models/cuenta_por_cobrar_detalle.dart';

class ReceivablesApi {
  ReceivablesApi(this._client);

  final ApiClient _client;

  Future<List<ClienteCobranza>> listarCobranza() async {
    try {
      final respuesta = await _client.dio.get('/cuentas-por-cobrar');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => ClienteCobranza.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<CuentaPorCobrarDetalle> obtenerCuenta(String clienteId) async {
    try {
      final respuesta = await _client.dio.get('/cuentas-por-cobrar/$clienteId');
      return CuentaPorCobrarDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<double> registrarAbono({
    required String clienteId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) async {
    try {
      final respuesta = await _client.dio.post('/cuentas-por-cobrar/$clienteId/abonos', data: {
        'monto': monto,
        'medioPago': medioPago.valorApi,
        'motivo': motivo,
      });
      return (respuesta.data['saldoActual'] as num).toDouble();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
