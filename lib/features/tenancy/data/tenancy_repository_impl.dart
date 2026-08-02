import '../domain/models/caja_resumen.dart';
import '../domain/tenancy_repository.dart';
import 'tenancy_api.dart';

class TenancyRepositoryImpl implements TenancyRepository {
  TenancyRepositoryImpl(this._api);

  final TenancyApi _api;

  @override
  Future<List<CajaResumen>> listarCajas() => _api.listarCajas();
}
