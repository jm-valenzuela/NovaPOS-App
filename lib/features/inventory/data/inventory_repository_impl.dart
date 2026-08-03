import '../domain/inventory_repository.dart';
import '../domain/models/stock_variante.dart';
import 'inventario_api.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._api);

  final InventarioApi _api;

  @override
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds}) =>
      _api.listarStock(bodegaId: bodegaId, varianteProductoIds: varianteProductoIds);
}
