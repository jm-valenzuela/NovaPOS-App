import '../domain/models/cotizacion.dart';
import '../domain/models/descuento_pendiente.dart';
import '../domain/models/detalle_descuento_pendiente.dart';
import '../domain/models/estado_descuento_venta.dart';
import '../domain/models/pago_input.dart';
import '../domain/models/resumen_venta.dart';
import '../domain/models/venta_detalle.dart';
import '../domain/models/venta_enums.dart';
import '../domain/sales_repository.dart';
import 'venta_api.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._api);

  final VentaApi _api;

  @override
  Future<String> crearVenta({required String cajaId, String? clienteId}) => _api.crear(
        cajaId: cajaId,
        clienteId: clienteId,
        formaPago: FormaPago.contado,
        tipoEntrega: TipoEntrega.inmediata,
      );

  @override
  Future<String> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad}) =>
      _api.agregarLinea(ventaId: ventaId, varianteProductoId: varianteProductoId, cantidad: cantidad);

  @override
  Future<void> actualizarLinea({required String ventaId, required String lineaVentaId, required double cantidad}) =>
      _api.actualizarLinea(ventaId: ventaId, lineaVentaId: lineaVentaId, cantidad: cantidad);

  @override
  Future<void> quitarLinea({required String ventaId, required String lineaVentaId}) =>
      _api.quitarLinea(ventaId: ventaId, lineaVentaId: lineaVentaId);

  @override
  Future<String> agregarLineaLibre({required String ventaId, required String descripcion, required double monto}) =>
      _api.agregarLineaLibre(ventaId: ventaId, descripcion: descripcion, monto: monto);

  @override
  Future<void> quitarLineaLibre({required String ventaId, required String lineaLibreId}) =>
      _api.quitarLineaLibre(ventaId: ventaId, lineaLibreId: lineaLibreId);

  @override
  Future<ResumenVenta> confirmarVenta({
    required String ventaId,
    required TipoDocumento tipoDocumento,
    required List<PagoInput> pagos,
    bool permitirVentaSinStock = false,
  }) =>
      _api.confirmar(ventaId: ventaId, tipoDocumento: tipoDocumento, pagos: pagos, permitirVentaSinStock: permitirVentaSinStock);

  @override
  Future<void> solicitarDescuentoGeneral({required String ventaId, double? porcentaje, double? monto}) =>
      _api.solicitarDescuento(ventaId: ventaId, porcentaje: porcentaje, monto: monto);

  @override
  Future<EstadoDescuentoVenta> obtenerEstadoDescuento(String ventaId) => _api.obtenerEstadoDescuento(ventaId);

  @override
  Future<List<DescuentoPendiente>> listarDescuentosPendientes() => _api.listarDescuentosPendientes();

  @override
  Future<DetalleDescuentoPendiente> obtenerDetalleDescuentoPendiente(String ventaId) =>
      _api.obtenerDetalleDescuentoPendiente(ventaId);

  @override
  Future<void> autorizarDescuentoGeneral(String ventaId) => _api.autorizarDescuento(ventaId);

  @override
  Future<void> rechazarDescuentoGeneral({required String ventaId, required String motivo}) =>
      _api.rechazarDescuento(ventaId: ventaId, motivo: motivo);

  @override
  Future<void> marcarComoCotizacion(String ventaId) => _api.marcarComoCotizacion(ventaId);

  @override
  Future<List<CotizacionResumen>> listarCotizaciones(String sucursalId) => _api.listarCotizaciones(sucursalId);

  @override
  Future<CotizacionDetalle> obtenerCotizacion(String ventaId) => _api.obtenerCotizacion(ventaId);

  @override
  Future<VentaDetalle> obtenerVenta(String ventaId) => _api.obtenerVenta(ventaId);
}
