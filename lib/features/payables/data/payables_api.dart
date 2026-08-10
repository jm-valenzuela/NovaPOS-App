import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../sales/domain/models/venta_enums.dart';
import '../domain/models/cuenta_por_pagar_detalle.dart';
import '../domain/models/proveedor_por_pagar.dart';

class PayablesApi {
  PayablesApi(this._client);

  final ApiClient _client;

  Future<List<ProveedorPorPagar>> listarCuentasPorPagar() async {
    try {
      final respuesta = await _client.dio.get('/cuentas-por-pagar');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => ProveedorPorPagar.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<CuentaPorPagarDetalle> obtenerCuenta(String proveedorId) async {
    try {
      final respuesta = await _client.dio.get('/cuentas-por-pagar/$proveedorId');
      return CuentaPorPagarDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<double> registrarPago({
    required String proveedorId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) async {
    try {
      final respuesta = await _client.dio.post('/cuentas-por-pagar/$proveedorId/abonos', data: {
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
