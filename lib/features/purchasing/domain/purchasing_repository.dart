import 'models/discrepancia.dart';
import 'models/documento_recibido.dart';
import 'models/orden_compra.dart';
import 'models/plazo_pago.dart';
import 'models/proveedor.dart';
import 'models/purchasing_enums.dart';

abstract class PurchasingRepository {
  // Proveedores
  Future<String> crearProveedor({
    required String rut,
    required String nombre,
    String? email,
    String? telefono,
    String? plazoPagoId,
  });

  Future<void> actualizarProveedor({
    required String proveedorId,
    required String nombre,
    String? email,
    String? telefono,
    String? plazoPagoId,
  });

  Future<List<ProveedorResumen>> buscarProveedores({String? texto});

  // Órdenes de Compra — flujo de 4 pasos: crear → agregar líneas → enviar → recibir.
  Future<String> crearOrdenCompra({required String proveedorId, required String bodegaDestinoId, FormaPago formaPago = FormaPago.contado});

  Future<void> agregarLineaOrdenCompra({
    required String ordenCompraId,
    required String varianteProductoId,
    required double cantidad,
    required double costoUnitario,
  });

  Future<void> enviarOrdenCompra(String ordenCompraId);

  /// `lineas` es Variante→CantidadRecibida — soporta recepción parcial,
  /// puede llamarse varias veces mientras queden líneas pendientes.
  Future<void> recibirOrdenCompra({required String ordenCompraId, required Map<String, double> lineas});

  Future<OrdenCompraDetalle> obtenerOrdenCompra(String ordenCompraId);

  Future<List<OrdenCompraResumenListado>> listarOrdenesCompra({String? proveedorId, EstadoOrdenCompra? estado});

  // Documentos Recibidos — la Boleta/Factura real del Proveedor.
  Future<String> registrarDocumentoRecibido({
    required String proveedorId,
    String? ordenCompraId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
  });

  Future<List<DocumentoRecibido>> listarDocumentosRecibidos(String proveedorId);

  // Discrepancias — siempre generadas por el sistema, nunca a mano.
  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado});

  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo});

  // Catálogo de Plazos de Pago (Proveedores) — ver PlazosPagoProveedorScreen.
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas});

  Future<List<PlazoPago>> listarPlazosPago();

  Future<void> activarPlazoPago(String plazoPagoId);

  Future<void> desactivarPlazoPago(String plazoPagoId);
}
