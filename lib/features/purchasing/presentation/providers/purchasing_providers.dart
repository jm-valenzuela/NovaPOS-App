import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/purchasing_api.dart';
import '../../data/purchasing_repository_impl.dart';
import '../../domain/models/discrepancia.dart';
import '../../domain/models/documento_recibido_global.dart';
import '../../domain/models/factura_interna.dart';
import '../../domain/models/orden_compra.dart';
import '../../domain/models/plazo_pago.dart';
import '../../domain/models/proveedor.dart';
import '../../domain/models/purchasing_enums.dart';
import '../../domain/purchasing_repository.dart';

final purchasingApiProvider = Provider<PurchasingApi>((ref) => PurchasingApi(ref.watch(apiClientProvider)));

final purchasingRepositoryProvider =
    Provider<PurchasingRepository>((ref) => PurchasingRepositoryImpl(ref.watch(purchasingApiProvider)));

// ---------------------------------------------------------------------------
// Proveedores
// ---------------------------------------------------------------------------

class ProveedoresState {
  const ProveedoresState({this.proveedores = const [], this.cargando = false, this.error});

  final List<ProveedorResumen> proveedores;
  final bool cargando;
  final String? error;

  ProveedoresState copyWith({List<ProveedorResumen>? proveedores, bool? cargando, String? error, bool limpiarError = false}) {
    return ProveedoresState(
      proveedores: proveedores ?? this.proveedores,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Listado con búsqueda (a diferencia de Catálogo, que trae todo de una vez
/// — la búsqueda de Proveedores ya pagina/filtra contra el backend, ver
/// BuscarProveedoresQuery) — tras crear o actualizar se recarga la lista
/// completa con el último texto buscado, mismo criterio que ProductosAdminController.
class ProveedoresController extends StateNotifier<ProveedoresState> {
  ProveedoresController(this._repository) : super(const ProveedoresState()) {
    cargar();
  }

  final PurchasingRepository _repository;
  String _ultimoTexto = '';

  Future<void> cargar({String? texto}) async {
    if (texto != null) _ultimoTexto = texto;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final proveedores = await _repository.buscarProveedores(texto: _ultimoTexto.isEmpty ? null : _ultimoTexto);
      state = state.copyWith(proveedores: proveedores, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> crear({required String rut, required String nombre, String? email, String? telefono, String? plazoPagoId}) async {
    try {
      await _repository.crearProveedor(rut: rut, nombre: nombre, email: email, telefono: telefono, plazoPagoId: plazoPagoId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> actualizar({
    required String proveedorId,
    required String nombre,
    String? email,
    String? telefono,
    String? plazoPagoId,
  }) async {
    try {
      await _repository.actualizarProveedor(proveedorId: proveedorId, nombre: nombre, email: email, telefono: telefono, plazoPagoId: plazoPagoId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final proveedoresProvider = StateNotifierProvider.autoDispose<ProveedoresController, ProveedoresState>((ref) {
  return ProveedoresController(ref.watch(purchasingRepositoryProvider));
});

class BusquedaProveedoresState {
  const BusquedaProveedoresState({this.resultados = const [], this.buscando = false});

  final List<ProveedorResumen> resultados;
  final bool buscando;

  BusquedaProveedoresState copyWith({List<ProveedorResumen>? resultados, bool? buscando}) {
    return BusquedaProveedoresState(resultados: resultados ?? this.resultados, buscando: buscando ?? this.buscando);
  }
}

/// Búsqueda con debounce para SelectorProveedorDialog — mismo patrón que
/// BusquedaClientesController (Sales), evita requerir pre-navegar a un
/// Proveedor existente para registrar una Factura Interna.
class BusquedaProveedoresController extends StateNotifier<BusquedaProveedoresState> {
  BusquedaProveedoresController(this._repository) : super(const BusquedaProveedoresState());

  final PurchasingRepository _repository;
  Timer? _debounce;
  int _peticionEnCurso = 0;

  void buscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _ejecutarBusqueda(texto));
  }

  Future<void> _ejecutarBusqueda(String texto) async {
    final idDeEstaPeticion = ++_peticionEnCurso;
    state = state.copyWith(buscando: true);
    try {
      final resultados = await _repository.buscarProveedores(texto: texto.isEmpty ? null : texto);
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(resultados: resultados, buscando: false);
    } catch (_) {
      if (idDeEstaPeticion != _peticionEnCurso) return;
      state = state.copyWith(buscando: false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final busquedaProveedoresProvider =
    StateNotifierProvider.autoDispose<BusquedaProveedoresController, BusquedaProveedoresState>((ref) {
  return BusquedaProveedoresController(ref.watch(purchasingRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Órdenes de Compra
// ---------------------------------------------------------------------------

class OrdenesCompraState {
  const OrdenesCompraState({this.ordenes = const [], this.cargando = false, this.error, this.filtroEstado});

  final List<OrdenCompraResumenListado> ordenes;
  final bool cargando;
  final String? error;
  final EstadoOrdenCompra? filtroEstado;

  OrdenesCompraState copyWith({
    List<OrdenCompraResumenListado>? ordenes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    EstadoOrdenCompra? filtroEstado,
    bool limpiarFiltro = false,
  }) {
    return OrdenesCompraState(
      ordenes: ordenes ?? this.ordenes,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      filtroEstado: limpiarFiltro ? null : (filtroEstado ?? this.filtroEstado),
    );
  }
}

/// Listado de Órdenes de Compra con filtro opcional por Estado — la
/// creación real (crear → agregar líneas → enviar → recibir) vive en
/// OrdenCompraDetalleController, este controller solo sostiene la lista.
class OrdenesCompraController extends StateNotifier<OrdenesCompraState> {
  OrdenesCompraController(this._repository) : super(const OrdenesCompraState()) {
    cargar();
  }

  final PurchasingRepository _repository;

  Future<void> cargar({EstadoOrdenCompra? filtroEstado, bool limpiarFiltro = false}) async {
    state = state.copyWith(cargando: true, limpiarError: true, filtroEstado: filtroEstado, limpiarFiltro: limpiarFiltro);
    try {
      final ordenes = await _repository.listarOrdenesCompra(estado: state.filtroEstado);
      state = state.copyWith(ordenes: ordenes, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }
}

final ordenesCompraProvider = StateNotifierProvider.autoDispose<OrdenesCompraController, OrdenesCompraState>((ref) {
  return OrdenesCompraController(ref.watch(purchasingRepositoryProvider));
});

class OrdenCompraDetalleState {
  const OrdenCompraDetalleState({this.orden, this.cargando = false, this.error});

  final OrdenCompraDetalle? orden;
  final bool cargando;
  final String? error;

  OrdenCompraDetalleState copyWith({OrdenCompraDetalle? orden, bool? cargando, String? error, bool limpiarError = false}) {
    return OrdenCompraDetalleState(
      orden: orden ?? this.orden,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Detalle de una Orden puntual — agregar línea/enviar/recibir siempre
/// recargan el detalle completo después, para reflejar el Total y las
/// CantidadRecibida/CantidadPendiente reales que calculó el servidor.
class OrdenCompraDetalleController extends StateNotifier<OrdenCompraDetalleState> {
  OrdenCompraDetalleController(this._repository, this.ordenCompraId) : super(const OrdenCompraDetalleState()) {
    cargar();
  }

  final PurchasingRepository _repository;
  final String ordenCompraId;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final orden = await _repository.obtenerOrdenCompra(ordenCompraId);
      state = state.copyWith(orden: orden, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> agregarLinea({required String varianteProductoId, required double cantidad, required double costoUnitario}) async {
    try {
      await _repository.agregarLineaOrdenCompra(
          ordenCompraId: ordenCompraId, varianteProductoId: varianteProductoId, cantidad: cantidad, costoUnitario: costoUnitario);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> enviar() async {
    try {
      await _repository.enviarOrdenCompra(ordenCompraId);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recibir(Map<String, double> lineas) async {
    try {
      await _repository.recibirOrdenCompra(ordenCompraId: ordenCompraId, lineas: lineas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final ordenCompraDetalleProvider =
    StateNotifierProvider.autoDispose.family<OrdenCompraDetalleController, OrdenCompraDetalleState, String>((ref, ordenCompraId) {
  return OrdenCompraDetalleController(ref.watch(purchasingRepositoryProvider), ordenCompraId);
});

// ---------------------------------------------------------------------------
// Documentos Recibidos
// ---------------------------------------------------------------------------

class DocumentosRecibidosState {
  const DocumentosRecibidosState({this.documentos = const [], this.cargando = false, this.error});

  final List<DocumentoRecibidoGlobal> documentos;
  final bool cargando;
  final String? error;

  DocumentosRecibidosState copyWith({List<DocumentoRecibidoGlobal>? documentos, bool? cargando, String? error, bool limpiarError = false}) {
    return DocumentosRecibidosState(
      documentos: documentos ?? this.documentos,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Documentos Recibidos globales — mercadería ligada a Orden de Compra y
/// Facturas Internas mezcladas, a través de todos los Proveedores (a
/// pedido explícito del usuario: entrar Proveedor por Proveedor "no es
/// efectivo, se supone que tendremos muchos proveedores").
class DocumentosRecibidosController extends StateNotifier<DocumentosRecibidosState> {
  DocumentosRecibidosController(this._repository) : super(const DocumentosRecibidosState()) {
    cargar();
  }

  final PurchasingRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final documentos = await _repository.listarTodosDocumentosRecibidos();
      state = state.copyWith(documentos: documentos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  /// Registra el documento y, si viene un `respaldo`, lo adjunta a
  /// continuación (segundo paso, mismo criterio que AgregarImagenVariante
  /// en Catálogo — el documento ya queda registrado aunque el adjunto falle).
  Future<bool> registrar({
    required String proveedorId,
    String? ordenCompraId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
    CategoriaDocumentoRecibido? categoria,
    List<int>? respaldoBytes,
    String? respaldoNombreArchivo,
  }) async {
    try {
      final documentoId = await _repository.registrarDocumentoRecibido(
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

      if (respaldoBytes != null && respaldoNombreArchivo != null) {
        await _repository.adjuntarRespaldoDocumentoRecibido(
          documentoRecibidoId: documentoId,
          bytes: respaldoBytes,
          nombreArchivo: respaldoNombreArchivo,
        );
      }

      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final documentosRecibidosProvider = StateNotifierProvider.autoDispose<DocumentosRecibidosController, DocumentosRecibidosState>((ref) {
  return DocumentosRecibidosController(ref.watch(purchasingRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Discrepancias
// ---------------------------------------------------------------------------

class DiscrepanciasState {
  const DiscrepanciasState({this.discrepancias = const [], this.cargando = false, this.error, this.filtroEstado = EstadoDiscrepancia.pendiente});

  final List<Discrepancia> discrepancias;
  final bool cargando;
  final String? error;

  /// Pendientes por defecto — es una cola de trabajo, no un archivo histórico.
  final EstadoDiscrepancia? filtroEstado;

  DiscrepanciasState copyWith({
    List<Discrepancia>? discrepancias,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    EstadoDiscrepancia? filtroEstado,
    bool limpiarFiltro = false,
  }) {
    return DiscrepanciasState(
      discrepancias: discrepancias ?? this.discrepancias,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
      filtroEstado: limpiarFiltro ? null : (filtroEstado ?? this.filtroEstado),
    );
  }
}

class DiscrepanciasController extends StateNotifier<DiscrepanciasState> {
  DiscrepanciasController(this._repository) : super(const DiscrepanciasState()) {
    cargar();
  }

  final PurchasingRepository _repository;

  Future<void> cargar({EstadoDiscrepancia? filtroEstado, bool limpiarFiltro = false}) async {
    state = state.copyWith(cargando: true, limpiarError: true, filtroEstado: filtroEstado, limpiarFiltro: limpiarFiltro);
    try {
      final discrepancias = await _repository.listarDiscrepancias(estado: state.filtroEstado);
      state = state.copyWith(discrepancias: discrepancias, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> resolver({required String discrepanciaId, required String motivo}) async {
    try {
      await _repository.resolverDiscrepancia(discrepanciaId: discrepanciaId, motivo: motivo);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final discrepanciasProvider = StateNotifierProvider.autoDispose<DiscrepanciasController, DiscrepanciasState>((ref) {
  return DiscrepanciasController(ref.watch(purchasingRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Plazos de Pago (Proveedores)
// ---------------------------------------------------------------------------

class PlazosPagoProveedorState {
  const PlazosPagoProveedorState({this.plazos = const [], this.cargando = false, this.error});

  final List<PlazoPago> plazos;
  final bool cargando;
  final String? error;

  PlazosPagoProveedorState copyWith({List<PlazoPago>? plazos, bool? cargando, String? error, bool limpiarError = false}) {
    return PlazosPagoProveedorState(
      plazos: plazos ?? this.plazos,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Catálogo de Plazos de Pago de Proveedores — espejo de PlazosPagoController
/// en Customers, mismo criterio de mantención separada.
class PlazosPagoProveedorController extends StateNotifier<PlazosPagoProveedorState> {
  PlazosPagoProveedorController(this._repository) : super(const PlazosPagoProveedorState()) {
    cargar();
  }

  final PurchasingRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final plazos = await _repository.listarPlazosPago();
      state = state.copyWith(plazos: plazos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<bool> crear({required String nombre, required List<int> diasCuotas}) async {
    try {
      await _repository.crearPlazoPago(nombre: nombre, diasCuotas: diasCuotas);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> activar(String plazoPagoId) async {
    await _repository.activarPlazoPago(plazoPagoId);
    await cargar();
  }

  Future<void> desactivar(String plazoPagoId) async {
    await _repository.desactivarPlazoPago(plazoPagoId);
    await cargar();
  }
}

final plazosPagoProveedorProvider = StateNotifierProvider.autoDispose<PlazosPagoProveedorController, PlazosPagoProveedorState>((ref) {
  return PlazosPagoProveedorController(ref.watch(purchasingRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Facturas Internas — DocumentosRecibidos sin Orden de Compra, listados a
// través de todos los Proveedores (pantalla propia e independiente de la
// mantención por Proveedor, a pedido explícito del usuario).
// ---------------------------------------------------------------------------

class FacturasInternasState {
  const FacturasInternasState({this.facturas = const [], this.cargando = false, this.error});

  final List<FacturaInterna> facturas;
  final bool cargando;
  final String? error;

  FacturasInternasState copyWith({List<FacturaInterna>? facturas, bool? cargando, String? error, bool limpiarError = false}) {
    return FacturasInternasState(
      facturas: facturas ?? this.facturas,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class FacturasInternasController extends StateNotifier<FacturasInternasState> {
  FacturasInternasController(this._repository) : super(const FacturasInternasState()) {
    cargar();
  }

  final PurchasingRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final facturas = await _repository.listarFacturasInternas();
      state = state.copyWith(facturas: facturas, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  /// Registra la Factura Interna y, si viene un `respaldo`, lo adjunta a
  /// continuación (segundo paso, mismo criterio que AgregarImagenVariante en
  /// Catálogo — la Factura ya queda registrada aunque el adjunto falle).
  Future<bool> registrar({
    required String proveedorId,
    required TipoDocumentoRecibido tipoDocumento,
    required int folio,
    required String rutEmisor,
    required double montoTotal,
    required FormaPago formaPago,
    required DateTime fechaEmision,
    required CategoriaDocumentoRecibido categoria,
    List<int>? respaldoBytes,
    String? respaldoNombreArchivo,
  }) async {
    try {
      final documentoId = await _repository.registrarDocumentoRecibido(
        proveedorId: proveedorId,
        ordenCompraId: null,
        tipoDocumento: tipoDocumento,
        folio: folio,
        rutEmisor: rutEmisor,
        montoTotal: montoTotal,
        formaPago: formaPago,
        fechaEmision: fechaEmision,
        categoria: categoria,
      );

      if (respaldoBytes != null && respaldoNombreArchivo != null) {
        await _repository.adjuntarRespaldoDocumentoRecibido(
          documentoRecibidoId: documentoId,
          bytes: respaldoBytes,
          nombreArchivo: respaldoNombreArchivo,
        );
      }

      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final facturasInternasProvider = StateNotifierProvider.autoDispose<FacturasInternasController, FacturasInternasState>((ref) {
  return FacturasInternasController(ref.watch(purchasingRepositoryProvider));
});
