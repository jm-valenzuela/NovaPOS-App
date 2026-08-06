import '../domain/models/discrepancia.dart';
import '../domain/models/documento_recibido.dart';
import '../domain/models/orden_compra.dart';
import '../domain/models/proveedor.dart';
import '../domain/models/purchasing_enums.dart';
import '../domain/purchasing_repository.dart';
import 'purchasing_api.dart';

class PurchasingRepositoryImpl implements PurchasingRepository {
  PurchasingRepositoryImpl(this._api);

  final PurchasingApi _api;

  @override
  Future<String> crearProveedor({required String rut, required String nombre, String? email, String? telefono, int plazoPagoDias = 0}) =>
      _api.crearProveedor(rut: rut, nombre: nombre, email: email, telefono: telefono, plazoPagoDias: plazoPagoDias);

  @override
  Future<void> actualizarProveedor({
    required String proveedorId,
    required String nombre,
    String? email,
    String? telefono,
    int plazoPagoDias = 0,
  }) =>
      _api.actualizarProveedor(proveedorId: proveedorId, nombre: nombre, email: email, telefono: telefono, plazoPagoDias: plazoPagoDias);

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
      );

  @override
  Future<List<DocumentoRecibido>> listarDocumentosRecibidos(String proveedorId) => _api.listarDocumentosRecibidos(proveedorId);

  @override
  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado}) => _api.listarDiscrepancias(estado: estado);

  @override
  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo}) =>
      _api.resolverDiscrepancia(discrepanciaId: discrepanciaId, motivo: motivo);
}
