import 'models/inventory_enums.dart';
import 'models/stock_variante.dart';
import 'models/tarjeta_existencia.dart';
import 'models/toma_inventario.dart';
import 'models/traslado_inventario.dart';

abstract class InventoryRepository {
  /// Una Variante sin Existencia registrada simplemente no aparece en el
  /// resultado (no es lo mismo que "stock cero") — mismo criterio que el backend.
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds});

  // Ajustes de Inventario (Tomas) — abrir → registrar conteos → cerrar.
  Future<List<TomaInventarioListado>> listarTomas({String? bodegaId, EstadoTomaInventario? estado});

  Future<String> abrirToma({required String bodegaId});

  Future<void> registrarConteo({required String tomaId, required String varianteProductoId, required double cantidadContada});

  Future<void> cerrarToma(String tomaId);

  Future<TomaInventarioDetalle> obtenerToma(String tomaId);

  // Traslados — crear → agregar líneas → enviar → recibir (soporta recepción parcial).
  Future<List<TrasladoListado>> listarTraslados({String? bodegaId, EstadoTraslado? estado});

  Future<String> crearTraslado({required String bodegaOrigenId, required String bodegaDestinoId});

  Future<void> agregarLineaTraslado({required String trasladoId, required String varianteProductoId, required double cantidad});

  Future<void> enviarTraslado(String trasladoId);

  /// `lineas` es Variante→CantidadRecibida — puede llamarse varias veces
  /// mientras queden líneas pendientes.
  Future<void> recibirTraslado({required String trasladoId, required Map<String, double> lineas});

  Future<TrasladoDetalle> obtenerTraslado(String trasladoId);

  // Tarjeta de Existencia (Kardex).
  Future<List<LineaTarjetaExistencia>> obtenerTarjetaExistencia({required String bodegaId, required String varianteProductoId});
}
