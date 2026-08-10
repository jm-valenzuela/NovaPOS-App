import '../domain/inventory_repository.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/stock_variante.dart';
import '../domain/models/tarjeta_existencia.dart';
import '../domain/models/toma_inventario.dart';
import '../domain/models/traslado_inventario.dart';
import 'inventario_api.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._api);

  final InventarioApi _api;

  @override
  Future<List<StockVariante>> listarStock({required String bodegaId, required List<String> varianteProductoIds}) =>
      _api.listarStock(bodegaId: bodegaId, varianteProductoIds: varianteProductoIds);

  @override
  Future<List<TomaInventarioListado>> listarTomas({String? bodegaId, EstadoTomaInventario? estado}) =>
      _api.listarTomas(bodegaId: bodegaId, estado: estado);

  @override
  Future<String> abrirToma({required String bodegaId}) => _api.abrirToma(bodegaId: bodegaId);

  @override
  Future<void> registrarConteo({required String tomaId, required String varianteProductoId, required double cantidadContada}) =>
      _api.registrarConteo(tomaId: tomaId, varianteProductoId: varianteProductoId, cantidadContada: cantidadContada);

  @override
  Future<void> cerrarToma(String tomaId) => _api.cerrarToma(tomaId);

  @override
  Future<TomaInventarioDetalle> obtenerToma(String tomaId) => _api.obtenerToma(tomaId);

  @override
  Future<List<TrasladoListado>> listarTraslados({String? bodegaId, EstadoTraslado? estado}) =>
      _api.listarTraslados(bodegaId: bodegaId, estado: estado);

  @override
  Future<String> crearTraslado({required String bodegaOrigenId, required String bodegaDestinoId}) =>
      _api.crearTraslado(bodegaOrigenId: bodegaOrigenId, bodegaDestinoId: bodegaDestinoId);

  @override
  Future<void> agregarLineaTraslado({required String trasladoId, required String varianteProductoId, required double cantidad}) =>
      _api.agregarLineaTraslado(trasladoId: trasladoId, varianteProductoId: varianteProductoId, cantidad: cantidad);

  @override
  Future<void> enviarTraslado(String trasladoId) => _api.enviarTraslado(trasladoId);

  @override
  Future<void> recibirTraslado({required String trasladoId, required Map<String, double> lineas}) =>
      _api.recibirTraslado(trasladoId: trasladoId, lineas: lineas);

  @override
  Future<TrasladoDetalle> obtenerTraslado(String trasladoId) => _api.obtenerTraslado(trasladoId);

  @override
  Future<List<LineaTarjetaExistencia>> obtenerTarjetaExistencia({required String bodegaId, required String varianteProductoId}) =>
      _api.obtenerTarjetaExistencia(bodegaId: bodegaId, varianteProductoId: varianteProductoId);
}
