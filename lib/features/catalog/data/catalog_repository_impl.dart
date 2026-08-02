import '../domain/catalog_repository.dart';
import '../domain/models/producto_vendible.dart';
import 'catalogo_api.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._api);

  final CatalogoApi _api;

  @override
  Future<List<ProductoVendible>> buscarProductos({String? texto}) => _api.buscarProductos(texto: texto);
}
