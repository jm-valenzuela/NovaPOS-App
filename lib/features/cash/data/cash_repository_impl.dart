import '../domain/cash_repository.dart';
import '../domain/models/resumen_cierre_caja.dart';
import '../domain/models/retiro_caja_pendiente.dart';
import '../domain/models/sesion_caja.dart';
import 'cash_api.dart';

class CashRepositoryImpl implements CashRepository {
  CashRepositoryImpl(this._api);

  final CashApi _api;

  @override
  Future<String> abrirCaja({required String cajaId, required double montoInicial}) =>
      _api.abrirCaja(cajaId: cajaId, montoInicial: montoInicial);

  @override
  Future<SesionCaja?> obtenerSesionAbierta(String cajaId) => _api.obtenerSesionAbierta(cajaId);

  @override
  Future<String> solicitarRetiro({required String sesionCajaId, required double monto, required String motivo}) =>
      _api.solicitarRetiro(sesionCajaId: sesionCajaId, monto: monto, motivo: motivo);

  @override
  Future<List<RetiroCajaPendiente>> listarRetirosPendientes() => _api.listarRetirosPendientes();

  @override
  Future<void> autorizarRetiro(String retiroId) => _api.autorizarRetiro(retiroId);

  @override
  Future<void> rechazarRetiro({required String retiroId, required String motivo}) =>
      _api.rechazarRetiro(retiroId: retiroId, motivo: motivo);

  @override
  Future<ResumenCierreCaja> obtenerResumenCierre(String sesionCajaId) => _api.obtenerResumenCierre(sesionCajaId);

  @override
  Future<void> cerrarCaja({required String sesionCajaId, required double montoContado}) =>
      _api.cerrarCaja(sesionCajaId: sesionCajaId, montoContado: montoContado);
}
