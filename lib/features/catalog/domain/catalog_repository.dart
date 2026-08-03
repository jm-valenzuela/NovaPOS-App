import 'models/producto_vendible.dart';

abstract class CatalogRepository {
  Future<List<ProductoVendible>> buscarProductos({String? texto, String? departamentoId});
}
