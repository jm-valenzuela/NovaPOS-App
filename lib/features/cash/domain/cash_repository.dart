import 'models/resumen_cierre_caja.dart';
import 'models/retiro_caja_pendiente.dart';
import 'models/sesion_caja.dart';

/// Contrato de Caja (Bounded Context Cash) — apertura con monto inicial
/// declarado, Retiros de efectivo con autorización de Supervisor, y cierre
/// con conteo físico y diferencia calculada.
abstract class CashRepository {
  Future<String> abrirCaja({required String cajaId, required double montoInicial});

  Future<SesionCaja?> obtenerSesionAbierta(String cajaId);

  Future<String> solicitarRetiro({required String sesionCajaId, required double monto, required String motivo});

  Future<List<RetiroCajaPendiente>> listarRetirosPendientes();

  Future<void> autorizarRetiro(String retiroId);

  Future<void> rechazarRetiro({required String retiroId, required String motivo});

  Future<ResumenCierreCaja> obtenerResumenCierre(String sesionCajaId);

  Future<void> cerrarCaja({required String sesionCajaId, required double montoContado});
}
