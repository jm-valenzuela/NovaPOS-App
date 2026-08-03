import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/catalog_admin_api.dart';
import '../../data/catalog_admin_repository_impl.dart';
import '../../domain/catalog_admin_repository.dart';
import '../../domain/models/producto_admin.dart';

final catalogAdminApiProvider = Provider<CatalogAdminApi>((ref) => CatalogAdminApi(ref.watch(apiClientProvider)));

final catalogAdminRepositoryProvider =
    Provider<CatalogAdminRepository>((ref) => CatalogAdminRepositoryImpl(ref.watch(catalogAdminApiProvider)));

class ProductosAdminState {
  const ProductosAdminState({this.productos = const [], this.cargando = false, this.error});

  final List<ProductoAdmin> productos;
  final bool cargando;
  final String? error;

  ProductosAdminState copyWith({List<ProductoAdmin>? productos, bool? cargando, String? error, bool limpiarError = false}) {
    return ProductosAdminState(
      productos: productos ?? this.productos,
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Listado administrable de Catálogo — a diferencia de la búsqueda del POS,
/// no tiene debounce (no hay campo de texto) y expone activar/desactivar.
/// Tras cualquier cambio se recarga la lista completa en vez de mutar el
/// estado local, para no arriesgar divergencia con lo que quedó en el
/// servidor — el catálogo de una PyME es chico, así que el costo es bajo.
class ProductosAdminController extends StateNotifier<ProductosAdminState> {
  ProductosAdminController(this._repository) : super(const ProductosAdminState()) {
    cargar();
  }

  final CatalogAdminRepository _repository;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final productos = await _repository.listarProductos();
      state = state.copyWith(productos: productos, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> alternarProducto(ProductoAdmin producto) async {
    try {
      if (producto.activo) {
        await _repository.desactivarProducto(producto.productoId);
      } else {
        await _repository.activarProducto(producto.productoId);
      }
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> alternarVariante(VarianteAdmin variante) async {
    try {
      if (variante.activa) {
        await _repository.desactivarVariante(variante.varianteProductoId);
      } else {
        await _repository.activarVariante(variante.varianteProductoId);
      }
      await cargar();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final productosAdminProvider = StateNotifierProvider.autoDispose<ProductosAdminController, ProductosAdminState>((ref) {
  return ProductosAdminController(ref.watch(catalogAdminRepositoryProvider));
});
