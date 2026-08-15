import 'package:novapos_app/features/purchasing/domain/models/discrepancia.dart';
import 'package:novapos_app/features/purchasing/domain/models/documento_recibido_global.dart';
import 'package:novapos_app/features/purchasing/domain/models/factura_interna.dart';
import 'package:novapos_app/features/purchasing/domain/models/orden_compra.dart';
import 'package:novapos_app/features/purchasing/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/purchasing/domain/models/proveedor.dart';
import 'package:novapos_app/features/purchasing/domain/models/purchasing_enums.dart';
import 'package:novapos_app/features/purchasing/domain/purchasing_repository.dart';

class FakePurchasingRepository implements PurchasingRepository {
  String? errorAforzar;

  List<ProveedorResumen> proveedoresARetornar = [];
  String? ultimoTextoBuscado;
  String proveedorIdARetornar = 'proveedor-nuevo';
  String? ultimoProveedorIdActualizado;
  String? ultimoPlazoPagoIdCreado;
  String? ultimoPlazoPagoIdActualizado;

  String ordenCompraIdARetornar = 'orden-nueva';
  List<OrdenCompraResumenListado> ordenesARetornar = [];
  EstadoOrdenCompra? ultimoFiltroEstado;
  OrdenCompraDetalle? ordenDetalleARetornar;
  String? ultimaOrdenIdConsultada;
  bool enviarLlamado = false;
  Map<String, double>? ultimasLineasRecibidas;

  List<DocumentoRecibidoGlobal> documentosARetornar = [];

  List<Discrepancia> discrepanciasARetornar = [];
  String? ultimaDiscrepanciaResuelta;

  @override
  Future<String> crearProveedor({required String rut, required String nombre, String? email, String? telefono, String? plazoPagoId}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    ultimoPlazoPagoIdCreado = plazoPagoId;
    return proveedorIdARetornar;
  }

  @override
  Future<void> actualizarProveedor({required String proveedorId, required String nombre, String? email, String? telefono, String? plazoPagoId}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    ultimoProveedorIdActualizado = proveedorId;
    ultimoPlazoPagoIdActualizado = plazoPagoId;
  }

  @override
  Future<List<ProveedorResumen>> buscarProveedores({String? texto}) async {
    ultimoTextoBuscado = texto;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return proveedoresARetornar;
  }

  @override
  Future<String> crearOrdenCompra({required String proveedorId, required String bodegaDestinoId, FormaPago formaPago = FormaPago.contado}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ordenCompraIdARetornar;
  }

  @override
  Future<void> agregarLineaOrdenCompra({
    required String ordenCompraId,
    required String varianteProductoId,
    required double cantidad,
    required double costoUnitario,
  }) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> enviarOrdenCompra(String ordenCompraId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    enviarLlamado = true;
  }

  @override
  Future<void> recibirOrdenCompra({required String ordenCompraId, required Map<String, double> lineas}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    ultimasLineasRecibidas = lineas;
  }

  @override
  Future<OrdenCompraDetalle> obtenerOrdenCompra(String ordenCompraId) async {
    ultimaOrdenIdConsultada = ordenCompraId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ordenDetalleARetornar ??
        OrdenCompraDetalle(
          id: ordenCompraId,
          proveedorId: 'proveedor-1',
          bodegaDestinoId: 'bodega-1',
          formaPago: FormaPago.contado,
          estado: EstadoOrdenCompra.borrador,
          total: 0,
          fechaEnvio: null,
          fechaRecepcion: null,
          lineas: const [],
        );
  }

  @override
  Future<List<OrdenCompraResumenListado>> listarOrdenesCompra({String? proveedorId, EstadoOrdenCompra? estado}) async {
    ultimoFiltroEstado = estado;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ordenesARetornar;
  }

  String? ultimoOrdenCompraIdDocumento;
  CategoriaDocumentoRecibido? ultimaCategoriaDocumento;
  String? ultimoProveedorIdDocumentoRegistrado;
  String documentoIdARetornar = 'documento-nuevo';

  @override
  Future<String> registrarDocumentoRecibido({
    String? ordenCompraId,
    required String proveedorId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
    CategoriaDocumentoRecibido? categoria,
  }) async {
    ultimoOrdenCompraIdDocumento = ordenCompraId;
    ultimaCategoriaDocumento = categoria;
    ultimoProveedorIdDocumentoRegistrado = proveedorId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return documentoIdARetornar;
  }

  @override
  Future<List<DocumentoRecibidoGlobal>> listarTodosDocumentosRecibidos() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return documentosARetornar;
  }

  List<FacturaInterna> facturasInternasARetornar = [];
  String documentoRecibidoIdARespaldar = 'documento-respaldado';
  String? ultimoDocumentoIdConRespaldo;
  List<int>? ultimosBytesRespaldo;
  String? ultimoNombreArchivoRespaldo;
  String rutaRespaldoARetornar = '/archivos/documentos-recibidos/e/d/f.pdf';

  @override
  Future<List<FacturaInterna>> listarFacturasInternas() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return facturasInternasARetornar;
  }

  @override
  Future<String> adjuntarRespaldoDocumentoRecibido({
    required String documentoRecibidoId,
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    ultimoDocumentoIdConRespaldo = documentoRecibidoId;
    ultimosBytesRespaldo = bytes;
    ultimoNombreArchivoRespaldo = nombreArchivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return rutaRespaldoARetornar;
  }

  @override
  Future<List<Discrepancia>> listarDiscrepancias({EstadoDiscrepancia? estado}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return discrepanciasARetornar;
  }

  @override
  Future<void> resolverDiscrepancia({required String discrepanciaId, required String motivo}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    ultimaDiscrepanciaResuelta = discrepanciaId;
  }

  List<PlazoPago> plazosPagoARetornar = [];
  String? ultimoNombrePlazoPagoCreado;
  List<int>? ultimasDiasCuotasCreadas;
  String plazoPagoIdARetornar = 'plazo-nuevo';
  String? ultimoPlazoPagoIdActivado;
  String? ultimoPlazoPagoIdDesactivado;

  @override
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    ultimoNombrePlazoPagoCreado = nombre;
    ultimasDiasCuotasCreadas = diasCuotas;
    return plazoPagoIdARetornar;
  }

  @override
  Future<List<PlazoPago>> listarPlazosPago() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return plazosPagoARetornar;
  }

  @override
  Future<void> activarPlazoPago(String plazoPagoId) async {
    ultimoPlazoPagoIdActivado = plazoPagoId;
  }

  @override
  Future<void> desactivarPlazoPago(String plazoPagoId) async {
    ultimoPlazoPagoIdDesactivado = plazoPagoId;
  }
}
