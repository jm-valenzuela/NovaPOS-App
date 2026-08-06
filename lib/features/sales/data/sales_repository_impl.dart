import '../domain/models/cotizacion.dart';
import '../domain/models/descuento_pendiente.dart';
import '../domain/models/detalle_descuento_pendiente.dart';
import '../domain/models/estado_descuento_venta.dart';
import '../domain/models/resumen_venta.dart';
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
  Future<void> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad}) =>
      _api.agregarLinea(ventaId: ventaId, varianteProductoId: varianteProductoId, cantidad: cantidad);

  @override
  Future<ResumenVenta> confirmarVenta(String ventaId) => _api.confirmar(ventaId);

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
}
