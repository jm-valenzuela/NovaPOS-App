import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/producto_vendible.dart';

class CatalogoApi {
  CatalogoApi(this._client);

  final ApiClient _client;

  Future<List<ProductoVendible>> buscarProductos({String? texto}) async {
    try {
      final respuesta = await _client.dio.get('/catalogo/productos', queryParameters: {
        if (texto != null && texto.trim().isNotEmpty) 'texto': texto.trim(),
      });
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => ProductoVendible.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
