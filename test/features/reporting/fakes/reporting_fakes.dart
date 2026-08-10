import 'package:novapos_app/features/reporting/domain/models/flujo_caja_dia.dart';
import 'package:novapos_app/features/reporting/domain/reporting_repository.dart';

class FakeReportingRepository implements ReportingRepository {
  List<FlujoCajaDia> flujoCajaARetornar = [];
  String? errorAforzar;

  DateTime? ultimoDesdeConsultado;
  DateTime? ultimoHastaConsultado;

  @override
  Future<List<FlujoCajaDia>> obtenerFlujoCaja({required DateTime desde, required DateTime hasta}) async {
    ultimoDesdeConsultado = desde;
    ultimoHastaConsultado = hasta;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return flujoCajaARetornar;
  }
}
