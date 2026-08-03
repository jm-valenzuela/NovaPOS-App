import 'models/bodega_venta.dart';
import 'models/caja_resumen.dart';

abstract class TenancyRepository {
  Future<List<CajaResumen>> listarCajas();
  Future<BodegaVenta?> obtenerBodegaVenta(String sucursalId);
}
