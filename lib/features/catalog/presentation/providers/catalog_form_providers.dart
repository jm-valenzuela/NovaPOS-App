import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog_admin_repository.dart';
import '../../domain/models/clasificacion.dart';
import 'catalog_admin_providers.dart';

class CatalogFormState {
  const CatalogFormState({
    this.departamentos = const [],
    this.subDepartamentos = const [],
    this.clases = const [],
    this.subclases = const [],
    this.marcas = const [],
    this.departamentoId,
    this.subDepartamentoId,
    this.claseId,
    this.subclaseId,
    this.marcaId,
    this.cargandoInicial = false,
    this.cargandoNivel = false,
    this.guardando = false,
    this.error,
    this.resultado,
  });

  final List<Departamento> departamentos;
  final List<SubDepartamento> subDepartamentos;
  final List<Clase> clases;
  final List<Subclase> subclases;
  final List<Marca> marcas;

  final String? departamentoId;
  final String? subDepartamentoId;
  final String? claseId;
  final String? subclaseId;
  final String? marcaId;

  final bool cargandoInicial;
  final bool cargandoNivel;
  final bool guardando;
  final String? error;

  /// No nulo tras un guardado exitoso (creación o edición).
  final CrearProductoResultado? resultado;

  bool get clasificacionCompleta => subclaseId != null && marcaId != null;

  CatalogFormState copyWith({
    List<Departamento>? departamentos,
    List<SubDepartamento>? subDepartamentos,
    List<Clase>? clases,
    List<Subclase>? subclases,
    List<Marca>? marcas,
    String? departamentoId,
    String? subDepartamentoId,
    String? claseId,
    String? subclaseId,
    String? marcaId,
    bool? cargandoInicial,
    bool? cargandoNivel,
    bool? guardando,
    String? error,
    bool limpiarError = false,
    CrearProductoResultado? resultado,
    bool limpiarSubDepartamento = false,
    bool limpiarClase = false,
    bool limpiarSubclase = false,
  }) {
    return CatalogFormState(
      departamentos: departamentos ?? this.departamentos,
      subDepartamentos: subDepartamentos ?? (limpiarSubDepartamento ? const [] : this.subDepartamentos),
      clases: clases ?? (limpiarClase ? const [] : this.clases),
      subclases: subclases ?? (limpiarSubclase ? const [] : this.subclases),
      marcas: marcas ?? this.marcas,
      departamentoId: departamentoId ?? this.departamentoId,
      subDepartamentoId: limpiarSubDepartamento ? null : (subDepartamentoId ?? this.subDepartamentoId),
      claseId: limpiarClase ? null : (claseId ?? this.claseId),
      subclaseId: limpiarSubclase ? null : (subclaseId ?? this.subclaseId),
      marcaId: marcaId ?? this.marcaId,
      cargandoInicial: cargandoInicial ?? this.cargandoInicial,
      cargandoNivel: cargandoNivel ?? this.cargandoNivel,
      guardando: guardando ?? this.guardando,
      error: limpiarError ? null : (error ?? this.error),
      resultado: resultado ?? this.resultado,
    );
  }
}

/// Maneja los combos en cascada (Departamento→SubDepartamento→Clase→Subclase)
/// más Marca, con alta rápida en cada nivel — necesario porque una Empresa
/// recién registrada no tiene ninguna Categoría cargada, y sin esto no
/// habría forma de crear el primer Producto desde la app.
class CatalogFormController extends StateNotifier<CatalogFormState> {
  CatalogFormController(this._repository) : super(const CatalogFormState()) {
    cargarInicial();
  }

  final CatalogAdminRepository _repository;

  Future<void> cargarInicial() async {
    state = state.copyWith(cargandoInicial: true, limpiarError: true);
    try {
      final departamentos = await _repository.listarDepartamentos();
      final marcas = await _repository.listarMarcas();
      state = state.copyWith(departamentos: departamentos, marcas: marcas, cargandoInicial: false);
    } catch (e) {
      state = state.copyWith(cargandoInicial: false, error: e.toString());
    }
  }

  Future<void> seleccionarDepartamento(String id) async {
    state = state.copyWith(
      departamentoId: id, limpiarSubDepartamento: true, limpiarClase: true, limpiarSubclase: true, cargandoNivel: true);
    try {
      final subDepartamentos = await _repository.listarSubDepartamentos(id);
      state = state.copyWith(subDepartamentos: subDepartamentos, cargandoNivel: false);
    } catch (e) {
      state = state.copyWith(cargandoNivel: false, error: e.toString());
    }
  }

  Future<void> seleccionarSubDepartamento(String id) async {
    state = state.copyWith(subDepartamentoId: id, limpiarClase: true, limpiarSubclase: true, cargandoNivel: true);
    try {
      final clases = await _repository.listarClases(id);
      state = state.copyWith(clases: clases, cargandoNivel: false);
    } catch (e) {
      state = state.copyWith(cargandoNivel: false, error: e.toString());
    }
  }

  Future<void> seleccionarClase(String id) async {
    state = state.copyWith(claseId: id, limpiarSubclase: true, cargandoNivel: true);
    try {
      final subclases = await _repository.listarSubclases(id);
      state = state.copyWith(subclases: subclases, cargandoNivel: false);
    } catch (e) {
      state = state.copyWith(cargandoNivel: false, error: e.toString());
    }
  }

  void seleccionarSubclase(String id) {
    state = state.copyWith(subclaseId: id);
  }

  void seleccionarMarca(String id) {
    state = state.copyWith(marcaId: id);
  }

  /// Para el diálogo de edición: parte con la Subclase/Marca actuales del
  /// Producto ya seleccionadas, sin obligar a recorrer la cascada completa
  /// si no se va a cambiar la clasificación.
  void inicializarClasificacionExistente({required String subclaseId, required String marcaId}) {
    state = state.copyWith(subclaseId: subclaseId, marcaId: marcaId);
  }

  Future<void> crearDepartamento(String nombre) async {
    try {
      final id = await _repository.crearDepartamento(nombre);
      final departamentos = await _repository.listarDepartamentos();
      state = state.copyWith(departamentos: departamentos);
      await seleccionarDepartamento(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> crearSubDepartamento(String nombre) async {
    if (state.departamentoId == null) return;
    try {
      final id = await _repository.crearSubDepartamento(state.departamentoId!, nombre);
      final subDepartamentos = await _repository.listarSubDepartamentos(state.departamentoId!);
      state = state.copyWith(subDepartamentos: subDepartamentos);
      await seleccionarSubDepartamento(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> crearClase(String nombre) async {
    if (state.subDepartamentoId == null) return;
    try {
      final id = await _repository.crearClase(state.subDepartamentoId!, nombre);
      final clases = await _repository.listarClases(state.subDepartamentoId!);
      state = state.copyWith(clases: clases);
      await seleccionarClase(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> crearSubclase(String nombre) async {
    if (state.claseId == null) return;
    try {
      final id = await _repository.crearSubclase(state.claseId!, nombre);
      final subclases = await _repository.listarSubclases(state.claseId!);
      state = state.copyWith(subclases: subclases);
      seleccionarSubclase(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> crearMarca(String nombre) async {
    try {
      final id = await _repository.crearMarca(nombre);
      final marcas = await _repository.listarMarcas();
      state = state.copyWith(marcas: marcas);
      seleccionarMarca(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> crearProducto({
    required String nombre,
    String? descripcion,
    required String sku,
    required double precioVenta,
    required int unidadMedida,
    String? codigoBarras,
    String? color,
    String? talla,
    String? ubicacionFisica,
    int? cantidadMinimaDescuentoVolumen,
    double? porcentajeDescuentoVolumen,
  }) async {
    if (!state.clasificacionCompleta) return;

    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final resultado = await _repository.crearProducto(
        subclaseId: state.subclaseId!,
        marcaId: state.marcaId!,
        nombre: nombre,
        descripcion: descripcion,
        sku: sku,
        precioVenta: precioVenta,
        unidadMedida: unidadMedida,
        codigoBarras: codigoBarras,
        color: color,
        talla: talla,
        ubicacionFisica: ubicacionFisica,
        cantidadMinimaDescuentoVolumen: cantidadMinimaDescuentoVolumen,
        porcentajeDescuentoVolumen: porcentajeDescuentoVolumen,
      );
      state = state.copyWith(guardando: false, resultado: resultado);
    } catch (e) {
      state = state.copyWith(guardando: false, error: e.toString());
    }
  }

  Future<bool> actualizarProducto({
    required String productoId,
    required String nombre,
    String? descripcion,
  }) async {
    if (!state.clasificacionCompleta) return false;

    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      await _repository.actualizarProducto(
        productoId: productoId, nombre: nombre, descripcion: descripcion, subclaseId: state.subclaseId!, marcaId: state.marcaId!);
      state = state.copyWith(guardando: false);
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, error: e.toString());
      return false;
    }
  }
}

final catalogFormProvider = StateNotifierProvider.autoDispose<CatalogFormController, CatalogFormState>((ref) {
  return CatalogFormController(ref.watch(catalogAdminRepositoryProvider));
});
