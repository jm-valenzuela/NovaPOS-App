import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/stock_variante.dart';

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
}
