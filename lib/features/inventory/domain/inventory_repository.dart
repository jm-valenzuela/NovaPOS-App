import 'models/stock_variante.dart';

abstract class InventoryRepository {
  /// Una Variante sin Existencia registrada simplemente no aparece en el
  /// resultado (no es lo mismo que "stock cero") — mismo criterio que el backend.
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds});
}
