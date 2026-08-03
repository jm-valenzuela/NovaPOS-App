import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/catalog_admin_repository.dart';
import '../domain/models/clasificacion.dart';
import '../domain/models/producto_admin.dart';

/// Endpoints de administración de Catálogo — a diferencia de CatalogoApi
/// (búsqueda para el POS), estos permiten crear la jerarquía de
/// clasificación y editar/activar/desactivar Producto y Variante.
class CatalogAdminApi {
  CatalogAdminApi(this._client);

  final ApiClient _client;

  Future<List<Departamento>> listarDepartamentos() async {
    try {
      final respuesta = await _client.dio.get('/catalogo/departamentos');
      return (respuesta.data as List<dynamic>)
          .map((json) => Departamento.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<SubDepartamento>> listarSubDepartamentos(String departamentoId) async {
    try {
      final respuesta = await _client.dio
          .get('/catalogo/subdepartamentos', queryParameters: {'departamentoId': departamentoId});
      return (respuesta.data as List<dynamic>)
          .map((json) => SubDepartamento.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<Clase>> listarClases(String subDepartamentoId) async {
    try {
      final respuesta =
          await _client.dio.get('/catalogo/clases', queryParameters: {'subDepartamentoId': subDepartamentoId});
      return (respuesta.data as List<dynamic>).map((json) => Clase.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<Subclase>> listarSubclases(String claseId) async {
    try {
      final respuesta = await _client.dio.get('/catalogo/subclases', queryParameters: {'claseId': claseId});
      return (respuesta.data as List<dynamic>)
          .map((json) => Subclase.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<Marca>> listarMarcas() async {
    try {
      final respuesta = await _client.dio.get('/catalogo/marcas');
      return (respuesta.data as List<dynamic>).map((json) => Marca.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<ProductoAdmin>> listarProductos() async {
    try {
      final respuesta = await _client.dio.get('/catalogo/productos/todos');
      return (respuesta.data as List<dynamic>)
          .map((json) => ProductoAdmin.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearDepartamento(String nombre) async {
    try {
      final respuesta = await _client.dio.post('/catalogo/departamentos', data: {'nombre': nombre});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearSubDepartamento(String departamentoId, String nombre) async {
    try {
      final respuesta = await _client.dio
          .post('/catalogo/subdepartamentos', data: {'departamentoId': departamentoId, 'nombre': nombre});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearClase(String subDepartamentoId, String nombre) async {
    try {
      final respuesta =
          await _client.dio.post('/catalogo/clases', data: {'subDepartamentoId': subDepartamentoId, 'nombre': nombre});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearSubclase(String claseId, String nombre) async {
    try {
      final respuesta = await _client.dio.post('/catalogo/subclases', data: {'claseId': claseId, 'nombre': nombre});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearMarca(String nombre) async {
    try {
      final respuesta = await _client.dio.post('/catalogo/marcas', data: {'nombre': nombre});
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<CrearProductoResultado> crearProducto({
    required String subclaseId,
    required String marcaId,
    required String nombre,
    String? descripcion,
    required String sku,
    required double precioVenta,
    required int unidadMedida,
    String? codigoBarras,
    String? color,
    String? talla,
    String? ubicacionFisica,
  }) async {
    try {
      final respuesta = await _client.dio.post('/catalogo/productos', data: {
        'subclaseId': subclaseId,
        'marcaId': marcaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'sku': sku,
        'precioVenta': precioVenta,
        'unidadMedida': unidadMedida,
        'codigoBarras': codigoBarras,
        'color': color,
        'talla': talla,
        'ubicacionFisica': ubicacionFisica,
      });
      return CrearProductoResultado(
        productoId: respuesta.data['productoId'] as String,
        varianteProductoId: respuesta.data['varianteProductoId'] as String,
      );
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> actualizarProducto({
    required String productoId,
    required String nombre,
    String? descripcion,
    required String subclaseId,
    required String marcaId,
  }) async {
    try {
      await _client.dio.put('/catalogo/productos/$productoId', data: {
        'nombre': nombre,
        'descripcion': descripcion,
        'subclaseId': subclaseId,
        'marcaId': marcaId,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> activarProducto(String productoId) async {
    try {
      await _client.dio.post('/catalogo/productos/$productoId/activar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> desactivarProducto(String productoId) async {
    try {
      await _client.dio.post('/catalogo/productos/$productoId/desactivar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> actualizarVariante({
    required String varianteProductoId,
    required double precioVenta,
    required int unidadMedida,
    String? codigoBarras,
    String? color,
    String? talla,
    String? ubicacionFisica,
  }) async {
    try {
      await _client.dio.put('/catalogo/variantes/$varianteProductoId', data: {
        'precioVenta': precioVenta,
        'unidadMedida': unidadMedida,
        'codigoBarras': codigoBarras,
        'color': color,
        'talla': talla,
        'ubicacionFisica': ubicacionFisica,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> activarVariante(String varianteProductoId) async {
    try {
      await _client.dio.post('/catalogo/variantes/$varianteProductoId/activar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> desactivarVariante(String varianteProductoId) async {
    try {
      await _client.dio.post('/catalogo/variantes/$varianteProductoId/desactivar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
