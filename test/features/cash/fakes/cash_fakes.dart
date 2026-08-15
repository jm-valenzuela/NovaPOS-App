import 'package:novapos_app/features/cash/domain/cash_repository.dart';
import 'package:novapos_app/features/cash/domain/models/resumen_cierre_caja.dart';
import 'package:novapos_app/features/cash/domain/models/retiro_caja_pendiente.dart';
import 'package:novapos_app/features/cash/domain/models/sesion_caja.dart';

class FakeCashRepository implements CashRepository {
  SesionCaja? sesionAbiertaARetornar;
  List<RetiroCajaPendiente> retirosPendientesARetornar = [];
  ResumenCierreCaja? resumenCierreARetornar;
  String? errorAforzar;

  String? ultimoCajaIdAbierto;
  double? ultimoMontoInicial;
  String? ultimoSesionIdRetiroSolicitado;
  double? ultimoMontoRetiroSolicitado;
  String? ultimoMotivoRetiroSolicitado;
  String? ultimoRetiroIdAutorizado;
  String? ultimoRetiroIdRechazado;
  String? ultimoMotivoRechazoRetiro;
  String? ultimoSesionIdCerrado;
  double? ultimoMontoContado;

  @override
  Future<String> abrirCaja({required String cajaId, required double montoInicial}) async {
    ultimoCajaIdAbierto = cajaId;
    ultimoMontoInicial = montoInicial;
    if (errorAforzar != null) throw Exception(errorAforzar);
    sesionAbiertaARetornar = SesionCaja(
      id: 'sesion-nueva',
      cajaId: cajaId,
      montoInicial: montoInicial,
      abiertaPorUsuarioId: 'usuario-1',
      fechaApertura: DateTime(2026, 8, 11),
      estado: EstadoSesionCaja.abierta,
    );
    return 'sesion-nueva';
  }

  @override
  Future<SesionCaja?> obtenerSesionAbierta(String cajaId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return sesionAbiertaARetornar;
  }

  @override
  Future<String> solicitarRetiro({required String sesionCajaId, required double monto, required String motivo}) async {
    ultimoSesionIdRetiroSolicitado = sesionCajaId;
    ultimoMontoRetiroSolicitado = monto;
    ultimoMotivoRetiroSolicitado = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return 'retiro-nuevo';
  }

  @override
  Future<List<RetiroCajaPendiente>> listarRetirosPendientes() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return retirosPendientesARetornar;
  }

  @override
  Future<void> autorizarRetiro(String retiroId) async {
    ultimoRetiroIdAutorizado = retiroId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<void> rechazarRetiro({required String retiroId, required String motivo}) async {
    ultimoRetiroIdRechazado = retiroId;
    ultimoMotivoRechazoRetiro = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }

  @override
  Future<ResumenCierreCaja> obtenerResumenCierre(String sesionCajaId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return resumenCierreARetornar!;
  }

  @override
  Future<void> cerrarCaja({required String sesionCajaId, required double montoContado}) async {
    ultimoSesionIdCerrado = sesionCajaId;
    ultimoMontoContado = montoContado;
    if (errorAforzar != null) throw Exception(errorAforzar);
    resumenCierreARetornar = ResumenCierreCaja(
      sesionCajaId: resumenCierreARetornar!.sesionCajaId,
      cajaId: resumenCierreARetornar!.cajaId,
      montoInicial: resumenCierreARetornar!.montoInicial,
      totalVentasEfectivo: resumenCierreARetornar!.totalVentasEfectivo,
      totalVentasTarjetaDebito: resumenCierreARetornar!.totalVentasTarjetaDebito,
      totalVentasTarjetaCredito: resumenCierreARetornar!.totalVentasTarjetaCredito,
      totalVentasCredito: resumenCierreARetornar!.totalVentasCredito,
      totalRetiros: resumenCierreARetornar!.totalRetiros,
      montoEsperado: resumenCierreARetornar!.montoEsperado,
      montoContado: montoContado,
      diferencia: montoContado - resumenCierreARetornar!.montoEsperado,
      cerrada: true,
      movimientos: resumenCierreARetornar!.movimientos,
    );
  }
}
