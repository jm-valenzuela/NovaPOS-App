import 'models/bodega_resumen.dart';
import 'models/bodega_venta.dart';
import 'models/caja_resumen.dart';

abstract class TenancyRepository {
  Future<List<CajaResumen>> listarCajas();
  Future<BodegaVenta?> obtenerBodegaVenta(String sucursalId);

  /// Todas las Bodegas de la Empresa — usado por las pantallas de
  /// Inventario para elegir entre Bodegas (a diferencia de
  /// obtenerBodegaVenta, que solo resuelve la de venta de una Sucursal).
  Future<List<BodegaResumen>> listarBodegas();
}
