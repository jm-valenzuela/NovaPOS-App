import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/discrepancia.dart';
import '../domain/models/documento_recibido.dart';
import '../domain/models/orden_compra.dart';
import '../domain/models/proveedor.dart';
import '../domain/models/purchasing_enums.dart';

class PurchasingApi {
  PurchasingApi(this._client);

  final ApiClient _client;

  Future<String> crearProveedor({
    required String rut,
    required String nombre,
    String? email,
    String? telefono,
    int plazoPagoDias = 0,
  }) async {
    try {
      final respuesta = await _client.dio.post('/proveedores', data: {
        'rut': rut,
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'plazoPagoDias': plazoPagoDias,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> actualizarProveedor({
    required String proveedorId,
    required String nombre,
    String? email,
    String? telefono,
    int plazoPagoDias = 0,
  }) async {
    try {
      await _client.dio.put('/proveedores/$proveedorId', data: {
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'plazoPagoDias': plazoPagoDias,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<ProveedorResumen>> buscarProveedores({String? texto}) async {
    try {
      final respuesta = await _client.dio.get('/proveedores/buscar', queryParameters: {if (texto != null) 'texto': texto});
      return (respuesta.data as List<dynamic>).map((json) => ProveedorResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> crearOrdenCompra({required String proveedorId, required String bodegaDestinoId, FormaPago formaPago = FormaPago.contado}) async {
    try {
      final respuesta = await _client.dio.post('/ordenes-compra', data: {
        'proveedorId': proveedorId,
        'bodegaDestinoId': bodegaDestinoId,
        'formaPago': formaPago.valorApi,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> agregarLineaOrdenCompra({
    required String ordenCompraId,
    required String varianteProductoId,
    required double cantidad,
    required double costoUnitario,
  }) async {
    try {
      await _client.dio.post('/ordenes-compra/$ordenCompraId/lineas', data: {
        'varianteProductoId': varianteProductoId,
        'cantidad': cantidad,
        'costoUnitario': costoUnitario,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> enviarOrdenCompra(String ordenCompraId) async {
    try {
      await _client.dio.post('/ordenes-compra/$ordenCompraId/enviar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> recibirOrdenCompra({required String ordenCompraId, required Map<String, double> lineas}) async {
    try {
      await _client.dio.post('/ordenes-compra/$ordenCompraId/recibir', data: {
        'lineas': lineas.entries.map((e) => {'varianteProductoId': e.key, 'cantidadRecibida': e.value}).toList(),
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<OrdenCompraDetalle> obtenerOrdenCompra(String ordenCompraId) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-compra/$ordenCompraId');
      return OrdenCompraDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<OrdenCompraResumenListado>> listarOrdenesCompra({String? proveedorId, EstadoOrdenCompra? estado}) async {
    try {
      final respuesta = await _client.dio.get('/ordenes-compra', queryParameters: {
        if (proveedorId != null) 'proveedorId': proveedorId,
        if (estado != null) 'estado': estado.valorApi,
      });
      return (respuesta.data as List<dynamic>).map((json) => OrdenCompraResumenListado.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<String> registrarDocumentoRecibido({
    required String proveedorId,
    String? ordenCompraId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
  }) async {
    try {
      final respuesta = await _client.dio.post('/documentos-recibidos', data: {
        'proveedorId': proveedorId,
        'ordenCompraId': ordenCompraId,
        'tipoDocumento': tipoDocumento.valorApi,
        'folio': folio,
        'rutEmisor': rutEmisor,
        'montoTotal': montoTotal,
        'formaPago': formaPago.valorApi,
        'fechaEmision': fechaEmision.toIso8601String(),
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<DocumentoRecibido>> listarDocumentosRecibidos(String proveedorId) async {
    try {
      final respuesta = await _client.dio.get('/documentos-recibidos', queryParameters: {'proveedorId': proveedorId});
      return (respuesta.data as List<dynamic>).map((json) => DocumentoRecibido.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado}) async {
    try {
      final respuesta = await _client.dio.get('/discrepancias-documentos-recibidos', queryParameters: {
        if (estado != null) 'estado': estado.valorApi,
      });
      return (respuesta.data as List<dynamic>).map((json) => Discrepancia.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo}) async {
    try {
      await _client.dio.post('/discrepancias-documentos-recibidos/$discrepanciaId/resolver', data: {'motivo': motivo});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
