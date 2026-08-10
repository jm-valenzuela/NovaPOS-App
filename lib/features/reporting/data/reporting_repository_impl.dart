import '../domain/models/flujo_caja_dia.dart';
import '../domain/reporting_repository.dart';
import 'reporting_api.dart';

class ReportingRepositoryImpl implements ReportingRepository {
  ReportingRepositoryImpl(this._api);

  final ReportingApi _api;

  @override
  Future<List<FlujoCajaDia>> obtenerFlujoCaja({required DateTime desde, required DateTime hasta}) =>
      _api.obtenerFlujoCaja(desde: desde, hasta: hasta);
}
