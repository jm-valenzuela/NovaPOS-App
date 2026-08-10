import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/stock_variante.dart';
import '../domain/models/tarjeta_existencia.dart';
import '../domain/models/toma_inventario.dart';
import '../domain/models/traslado_inventario.dart';

class InventarioApi {
  InventarioApi(this._client);

  final ApiClient _client;

  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds}) async {
    if (varianteProductoIds.isEmpty) return [];

    try {
      final respuesta = await _client.dio.post(
        '/inventario/bodegas/$bodegaId/existencias/consultar',
        data: {'varianteProductoIds': varianteProductoIds},
      );
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => StockVariante.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  // ---------------------------------------------------------------------
  // Ajustes de Inventario (Tomas)
  // ---------------------------------------------------------------------

  Future<List<TomaInventarioListado>> listarTomas({String? bodegaId, EstadoTomaInventario? estado}) async {
    try {
      final respuesta = await _client.dio.get('/inventario/tomas', queryParameters: {
        if (bodegaId != null) 'bodegaId': bodegaId,
        if (estado != null) 'estado': estado.valorApi,
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => TomaInventarioListado.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> abrirToma({required String bodegaId}) async {
    try {
      final respuesta = await _client.dio.post('/inventario/tomas', data: {'bodegaId': bodegaId});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> registrarConteo({required String tomaId, required String varianteProductoId, required double cantidadContada}) async {
    try {
      await _client.dio.post('/inventario/tomas/$tomaId/conteos', data: {
        'varianteProductoId': varianteProductoId,
        'cantidadContada': cantidadContada,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> cerrarToma(String tomaId) async {
    try {
      await _client.dio.post('/inventario/tomas/$tomaId/cerrar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<TomaInventarioDetalle> obtenerToma(String tomaId) async {
    try {
      final respuesta = await _client.dio.get('/inventario/tomas/$tomaId');
      return TomaInventarioDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  // ---------------------------------------------------------------------
  // Traslados
  // ---------------------------------------------------------------------

  Future<List<TrasladoListado>> listarTraslados({String? bodegaId, EstadoTraslado? estado}) async {
    try {
      final respuesta = await _client.dio.get('/inventario/traslados', queryParameters: {
        if (bodegaId != null) 'bodegaId': bodegaId,
        if (estado != null) 'estado': estado.valorApi,
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => TrasladoListado.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearTraslado({required String bodegaOrigenId, required String bodegaDestinoId}) async {
    try {
      final respuesta = await _client.dio.post('/inventario/traslados', data: {
        'bodegaOrigenId': bodegaOrigenId,
        'bodegaDestinoId': bodegaDestinoId,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> agregarLineaTraslado({required String trasladoId, required String varianteProductoId, required double cantidad}) async {
    try {
      await _client.dio.post('/inventario/traslados/$trasladoId/lineas', data: {
        'varianteProductoId': varianteProductoId,
        'cantidad': cantidad,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> enviarTraslado(String trasladoId) async {
    try {
      await _client.dio.post('/inventario/traslados/$trasladoId/enviar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> recibirTraslado({required String trasladoId, required Map<String, double> lineas}) async {
    try {
      await _client.dio.post('/inventario/traslados/$trasladoId/recibir', data: {
        'lineas': lineas.entries.map((e) => {'varianteProductoId': e.key, 'cantidadRecibida': e.value}).toList(),
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<TrasladoDetalle> obtenerTraslado(String trasladoId) async {
    try {
      final respuesta = await _client.dio.get('/inventario/traslados/$trasladoId');
      return TrasladoDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  // ---------------------------------------------------------------------
  // Tarjeta de Existencia (Kardex)
  // ---------------------------------------------------------------------

  Future<List<LineaTarjetaExistencia>> obtenerTarjetaExistencia({required String bodegaId, required String varianteProductoId}) async {
    try {
      final respuesta = await _client.dio.get(
        '/inventario/bodegas/$bodegaId/tarjeta-existencia',
        queryParameters: {'varianteProductoId': varianteProductoId},
      );
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => LineaTarjetaExistencia.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
