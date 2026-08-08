import 'package:novapos_app/features/purchasing/domain/models/discrepancia.dart';
import 'package:novapos_app/features/purchasing/domain/models/documento_recibido.dart';
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

  List<DocumentoRecibido> documentosARetornar = [];
  String? ultimoProveedorIdDocumentos;

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
  }) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return 'documento-nuevo';
  }

  @override
  Future<List<DocumentoRecibido>> listarDocumentosRecibidos(String proveedorId) async {
    ultimoProveedorIdDocumentos = proveedorId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return documentosARetornar;
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
