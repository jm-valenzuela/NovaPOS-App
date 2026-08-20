import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/cotizacion.dart';
import '../domain/models/descuento_pendiente.dart';
import '../domain/models/detalle_descuento_pendiente.dart';
import '../domain/models/estado_descuento_venta.dart';
import '../domain/models/pago_input.dart';
import '../domain/models/resumen_venta.dart';
import '../domain/models/venta_detalle.dart';
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

  /// Devuelve el Id de la LineaVenta creada — necesario para poder editar/
  /// quitar esta línea puntual después (ver actualizarLinea/quitarLinea).
  Future<String> agregarLinea({
    required String ventaId,
    required String varianteProductoId,
    required double cantidad,
  }) async {
    try {
      final respuesta = await _client.dio.post('/ventas/$ventaId/lineas', data: {
        'varianteProductoId': varianteProductoId,
        'cantidad': cantidad,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Reemplaza la Cantidad de una línea ya agregada — el Precio unitario se
  /// resuelve de nuevo en el backend desde el Catálogo, no se manda acá.
  Future<void> actualizarLinea({required String ventaId, required String lineaVentaId, required double cantidad}) async {
    try {
      await _client.dio.put('/ventas/$ventaId/lineas/$lineaVentaId', data: {'cantidad': cantidad});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> quitarLinea({required String ventaId, required String lineaVentaId}) async {
    try {
      await _client.dio.delete('/ventas/$ventaId/lineas/$lineaVentaId');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// Línea sin Catálogo, precio a mano (ver LineaLibreVenta en el backend) — mano de obra u otro cargo que no es un Producto vendible.
  Future<String> agregarLineaLibre({required String ventaId, required String descripcion, required double monto}) async {
    try {
      final respuesta = await _client.dio.post('/ventas/$ventaId/lineas-libres', data: {
        'descripcion': descripcion,
        'monto': monto,
      });
      return respuesta.data['id'] as String;
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> quitarLineaLibre({required String ventaId, required String lineaLibreId}) async {
    try {
      await _client.dio.delete('/ventas/$ventaId/lineas-libres/$lineaLibreId');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<ResumenVenta> confirmar({
    required String ventaId,
    required TipoDocumento tipoDocumento,
    required List<PagoInput> pagos,
  }) async {
    try {
      final respuesta = await _client.dio.post('/ventas/$ventaId/confirmar', data: {
        'tipoDocumentoSolicitado': tipoDocumento.valorApi,
        'pagos': pagos.map((p) => p.toJson()).toList(),
      });
      return ResumenVenta.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// El Cajero pide el descuento — porcentaje y monto son mutuamente
  /// excluyentes, quien llama debe mandar exactamente uno de los dos.
  Future<void> solicitarDescuento({required String ventaId, double? porcentaje, double? monto}) async {
    try {
      await _client.dio.post('/ventas/$ventaId/descuento', data: {
        'porcentaje': porcentaje,
        'monto': monto,
      });
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<EstadoDescuentoVenta> obtenerEstadoDescuento(String ventaId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/$ventaId/descuento');
      return EstadoDescuentoVenta.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<List<DescuentoPendiente>> listarDescuentosPendientes() async {
    try {
      final respuesta = await _client.dio.get('/ventas/descuentos-pendientes');
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => DescuentoPendiente.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// "Ver más" en la cola de trabajo del Supervisor — Cliente y líneas
  /// (con nombre de Producto ya resuelto) de una Venta puntual.
  Future<DetalleDescuentoPendiente> obtenerDetalleDescuentoPendiente(String ventaId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/descuentos-pendientes/$ventaId');
      return DetalleDescuentoPendiente.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> autorizarDescuento(String ventaId) async {
    try {
      await _client.dio.post('/ventas/$ventaId/descuento/autorizar');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<void> rechazarDescuento({required String ventaId, required String motivo}) async {
    try {
      await _client.dio.post('/ventas/$ventaId/descuento/rechazar', data: {'motivo': motivo});
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// El Cajero guarda el carrito actual como Cotización en vez de cobrarlo — sigue en Borrador.
  Future<void> marcarComoCotizacion(String ventaId) async {
    try {
      await _client.dio.post('/ventas/$ventaId/cotizacion');
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  /// "Rescatar cotización" en el POS — Cotizaciones vigentes de la Sucursal de la Caja actual.
  Future<List<CotizacionResumen>> listarCotizaciones(String sucursalId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/cotizaciones', queryParameters: {'sucursalId': sucursalId});
      final lista = respuesta.data as List<dynamic>;
      return lista.map((json) => CotizacionResumen.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<CotizacionDetalle> obtenerCotizacion(String ventaId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/cotizaciones/$ventaId');
      return CotizacionDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }

  Future<VentaDetalle> obtenerVenta(String ventaId) async {
    try {
      final respuesta = await _client.dio.get('/ventas/$ventaId');
      return VentaDetalle.fromJson(respuesta.data as Map<String, dynamic>);
    } on DioException catch (e) {
      ApiClient.lanzarError(e);
    }
  }
}
