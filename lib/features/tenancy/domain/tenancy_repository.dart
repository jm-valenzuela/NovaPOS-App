import 'models/caja_resumen.dart';

abstract class TenancyRepository {
  Future<List<CajaResumen>> listarCajas();
}
