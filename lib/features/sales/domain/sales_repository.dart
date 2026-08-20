import 'models/cotizacion.dart';
import 'models/descuento_pendiente.dart';
import 'models/detalle_descuento_pendiente.dart';
import 'models/estado_descuento_venta.dart';
import 'models/pago_input.dart';
import 'models/resumen_venta.dart';
import 'models/venta_detalle.dart';
import 'models/venta_enums.dart';

/// Contrato para el flujo de cobro del POS — Crear Venta, agregar cada
/// línea, confirmar. El carrito en sí es estado de cliente puro (ver
/// LineaCarrito); esto solo cubre la parte que sí toca al backend.
abstract class SalesRepository {
  Future<String> crearVenta({required String cajaId, String? clienteId});

  /// Devuelve el Id de la LineaVenta creada.
  Future<String> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad});

  /// Cambia la Cantidad de una línea ya agregada — el backend rechaza esto
  /// mientras haya un descuento general Pendiente o Autorizado (ver
  /// Venta.GarantizarLineasEditables).
  Future<void> actualizarLinea({required String ventaId, required String lineaVentaId, required double cantidad});

  /// Mismo bloqueo que actualizarLinea.
  Future<void> quitarLinea({required String ventaId, required String lineaVentaId});

  /// Línea sin Catálogo, precio a mano — mano de obra u otro cargo que no
  /// es un Producto vendible (ej. Orden de Trabajo, ver workorders).
  /// Devuelve el Id de la línea creada.
  Future<String> agregarLineaLibre({required String ventaId, required String descripcion, required double monto});

  Future<void> quitarLineaLibre({required String ventaId, required String lineaLibreId});

  /// tipoDocumento: Boleta o Factura, elegido por el Cajero (ver
  /// CheckoutDialog). pagos: obligatorio y no vacío si la Venta es al
  /// Contado (soporta pago mixto); vacío si es a Crédito.
  Future<ResumenVenta> confirmarVenta({
    required String ventaId,
    required TipoDocumento tipoDocumento,
    required List<PagoInput> pagos,
  });

  /// El Cajero pide el descuento — porcentaje y monto son mutuamente
  /// excluyentes, mandar exactamente uno de los dos.
  Future<void> solicitarDescuentoGeneral({required String ventaId, double? porcentaje, double? monto});

  /// El POS del Cajero consulta esto mientras espera que alguien con
  /// "sales.descuentos.autorizar" resuelva la solicitud.
  Future<EstadoDescuentoVenta> obtenerEstadoDescuento(String ventaId);

  /// Cola de trabajo de quien autoriza descuentos.
  Future<List<DescuentoPendiente>> listarDescuentosPendientes();

  /// "Ver más" — Cliente y líneas de una Venta puntual de la cola.
  Future<DetalleDescuentoPendiente> obtenerDetalleDescuentoPendiente(String ventaId);

  Future<void> autorizarDescuentoGeneral(String ventaId);

  Future<void> rechazarDescuentoGeneral({required String ventaId, required String motivo});

  /// El Cajero guarda el carrito actual como Cotización en vez de cobrarlo.
  Future<void> marcarComoCotizacion(String ventaId);

  /// "Rescatar cotización" en el POS — Cotizaciones vigentes de la Sucursal.
  Future<List<CotizacionResumen>> listarCotizaciones(String sucursalId);

  /// Detalle completo para rehidratar el carrito al rescatar una Cotización.
  Future<CotizacionDetalle> obtenerCotizacion(String ventaId);

  /// Detalle de una Venta ya confirmada, con los datos del DTE emitido (si lo hay) — para mostrar/reimprimir la Boleta o Factura más adelante (ej. desde la Orden de Trabajo que la generó).
  Future<VentaDetalle> obtenerVenta(String ventaId);
}
