import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/resumen_cierre_caja.dart';
import '../domain/models/retiro_caja_pendiente.dart';
import '../domain/models/sesion_caja.dart';

class CashApi {
  CashApi(this._client);

  final ApiClient _client;

  Future<String> abrirCaja({required String cajaId, required double montoInicial}) async {
    try {
      final respuesta = await _client.dio.post('/caja/$cajaId/apertura', data: {'montoInicial': montoInicial});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<SesionCaja?> obtenerSesionAbierta(String cajaId) async {
    try {
      final respuesta = await _client.dio.get('/caja/$cajaId/sesion-abierta');
      final data = respuesta.data;
      if (data == null) return null;
      return SesionCaja.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> solicitarRetiro({required String sesionCajaId, required double monto, required String motivo}) async {
    try {
      final respuesta =
          await _client.dio.post('/caja/sesiones/$sesionCajaId/retiros', data: {'monto': monto, 'motivo': motivo});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<RetiroCajaPendiente>> listarRetirosPendientes() async {
    try {
      final respuesta = await _client.dio.get('/caja/retiros/pendientes');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => RetiroCajaPendiente.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> autorizarRetiro(String retiroId) async {
    try {
      await _client.dio.post('/caja/retiros/$retiroId/autorizar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> rechazarRetiro({required String retiroId, required String motivo}) async {
    try {
      await _client.dio.post('/caja/retiros/$retiroId/rechazar', data: {'motivo': motivo});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<ResumenCierreCaja> obtenerResumenCierre(String sesionCajaId) async {
    try {
      final respuesta = await _client.dio.get('/caja/sesiones/$sesionCajaId/resumen-cierre');
      return ResumenCierreCaja.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> cerrarCaja({required String sesionCajaId, required double montoContado}) async {
    try {
      await _client.dio.post('/caja/sesiones/$sesionCajaId/cierre', data: {'montoContado': montoContado});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
