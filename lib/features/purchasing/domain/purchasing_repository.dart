import 'models/discrepancia.dart';
import 'models/documento_recibido_global.dart';
import 'models/factura_interna.dart';
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
  // ordenCompraId es opcional (compra directa, "Factura Interna"); cuando
  // no viene, categoria es obligatoria — ver CategoriaDocumentoRecibido.
  Future<String> registrarDocumentoRecibido({
    required String proveedorId,
    String? ordenCompraId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
    CategoriaDocumentoRecibido? categoria,
  });

  /// Todos los Documentos Recibidos (mercadería + Facturas Internas) a
  /// través de todos los Proveedores — pantalla global, reemplaza tener
  /// que entrar Proveedor por Proveedor a pedido explícito del usuario.
  Future<List<DocumentoRecibidoGlobal>> listarTodosDocumentosRecibidos();

  // Facturas Internas — mismos DocumentosRecibidos sin Orden de Compra,
  // pero listados a través de todos los Proveedores (pantalla propia).
  Future<List<FacturaInterna>> listarFacturasInternas();

  /// Respaldo (Foto o PDF) de una Factura Interna ya registrada — un solo
  /// archivo por documento, ver DocumentoRecibido.AdjuntarRespaldo.
  Future<String> adjuntarRespaldoDocumentoRecibido({
    required String documentoRecibidoId,
    required List<int> bytes,
    required String nombreArchivo,
  });

  // Discrepancias — siempre generadas por el sistema, nunca a mano.
  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado});

  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo});

  // Catálogo de Plazos de Pago (Proveedores) — ver PlazosPagoProveedorScreen.
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas});

  Future<List<PlazoPago>> listarPlazosPago();

  Future<void> activarPlazoPago(String plazoPagoId);

  Future<void> desactivarPlazoPago(String plazoPagoId);
}
