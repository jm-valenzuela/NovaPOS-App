import '../domain/models/discrepancia.dart';
import '../domain/models/documento_recibido_global.dart';
import '../domain/models/factura_interna.dart';
import '../domain/models/orden_compra.dart';
import '../domain/models/plazo_pago.dart';
import '../domain/models/proveedor.dart';
import '../domain/models/purchasing_enums.dart';
import '../domain/purchasing_repository.dart';
import 'purchasing_api.dart';

class PurchasingRepositoryImpl implements PurchasingRepository {
  PurchasingRepositoryImpl(this._api);

  final PurchasingApi _api;

  @override
  Future<String> crearProveedor({required String rut, required String nombre, String? email, String? telefono, String? plazoPagoId}) =>
      _api.crearProveedor(rut: rut, nombre: nombre, email: email, telefono: telefono, plazoPagoId: plazoPagoId);

  @override
  Future<void> actualizarProveedor({
    required String proveedorId,
    required String nombre,
    String? email,
    String? telefono,
    String? plazoPagoId,
  }) =>
      _api.actualizarProveedor(proveedorId: proveedorId, nombre: nombre, email: email, telefono: telefono, plazoPagoId: plazoPagoId);

  @override
  Future<List<ProveedorResumen>> buscarProveedores({String? texto}) => _api.buscarProveedores(texto: texto);

  @override
  Future<String> crearOrdenCompra({required String proveedorId, required String bodegaDestinoId, FormaPago formaPago = FormaPago.contado}) =>
      _api.crearOrdenCompra(proveedorId: proveedorId, bodegaDestinoId: bodegaDestinoId, formaPago: formaPago);

  @override
  Future<void> agregarLineaOrdenCompra({
    required String ordenCompraId,
    required String varianteProductoId,
    required double cantidad,
    required double costoUnitario,
  }) =>
      _api.agregarLineaOrdenCompra(ordenCompraId: ordenCompraId, varianteProductoId: varianteProductoId, cantidad: cantidad, costoUnitario: costoUnitario);

  @override
  Future<void> enviarOrdenCompra(String ordenCompraId) => _api.enviarOrdenCompra(ordenCompraId);

  @override
  Future<void> recibirOrdenCompra({required String ordenCompraId, required Map<String, double> lineas}) =>
      _api.recibirOrdenCompra(ordenCompraId: ordenCompraId, lineas: lineas);

  @override
  Future<OrdenCompraDetalle> obtenerOrdenCompra(String ordenCompraId) => _api.obtenerOrdenCompra(ordenCompraId);

  @override
  Future<List<OrdenCompraResumenListado>> listarOrdenesCompra({String? proveedorId, EstadoOrdenCompra? estado}) =>
      _api.listarOrdenesCompra(proveedorId: proveedorId, estado: estado);

  @override
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
  }) =>
      _api.registrarDocumentoRecibido(
        proveedorId: proveedorId,
        ordenCompraId: ordenCompraId,
        tipoDocumento: tipoDocumento,
        folio: folio,
        rutEmisor: rutEmisor,
        montoTotal: montoTotal,
        formaPago: formaPago,
        fechaEmision: fechaEmision,
        categoria: categoria,
      );

  @override
  Future<List<DocumentoRecibidoGlobal>> listarTodosDocumentosRecibidos() => _api.listarTodosDocumentosRecibidos();

  @override
  Future<List<FacturaInterna>> listarFacturasInternas() => _api.listarFacturasInternas();

  @override
  Future<String> adjuntarRespaldoDocumentoRecibido({
    required String documentoRecibidoId,
    required List<int> bytes,
    required String nombreArchivo,
  }) =>
      _api.adjuntarRespaldoDocumentoRecibido(documentoRecibidoId: documentoRecibidoId, bytes: bytes, nombreArchivo: nombreArchivo);

  @override
  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado}) => _api.listarDiscrepancias(estado: estado);

  @override
  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo}) =>
      _api.resolverDiscrepancia(discrepanciaId: discrepanciaId, motivo: motivo);

  @override
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas}) =>
      _api.crearPlazoPago(nombre: nombre, diasCuotas: diasCuotas);

  @override
  Future<List<PlazoPago>> listarPlazosPago() => _api.listarPlazosPago();

  @override
  Future<void> activarPlazoPago(String plazoPagoId) => _api.activarPlazoPago(plazoPagoId);

  @override
  Future<void> desactivarPlazoPago(String plazoPagoId) => _api.desactivarPlazoPago(plazoPagoId);
}
