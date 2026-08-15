import 'package:novapos_app/features/returns/domain/models/linea_devolucion_input.dart';
import 'package:novapos_app/features/returns/domain/models/nota_credito_cliente_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/nota_credito_disponible_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/venta_confirmada_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/venta_para_devolucion_detalle.dart';
import 'package:novapos_app/features/returns/domain/returns_repository.dart';

class FakeReturnsRepository implements ReturnsRepository {
  List<VentaConfirmadaResumen> ventasARetornar = [];
  VentaParaDevolucionDetalle? detalleARetornar;
  List<NotaCreditoClienteResumen> notasARetornar = [];
  List<NotaCreditoDisponibleResumen> notasDisponiblesARetornar = [];
  String idADevolver = 'nota-nueva-1';
  String? errorAforzar;

  String? ultimaVentaOrigenIdRegistrada;
  String? ultimoClienteIdRegistrado;
  List<LineaDevolucionInput>? ultimasLineasRegistradas;
  String? ultimoMotivoRegistrado;
  bool? ultimoReembolsarEnEfectivo;
  String? ultimaSesionCajaIdRegistrada;
  String? ultimaNotaCreditoIdReembolsada;
  String? ultimaSesionCajaIdDeReembolso;

  @override
  Future<List<VentaConfirmadaResumen>> listarVentasConfirmadas(String sucursalId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return ventasARetornar;
  }

  @override
  Future<VentaParaDevolucionDetalle> obtenerVentaParaDevolucion(String ventaId) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return detalleARetornar!;
  }

  @override
  Future<String> registrarDevolucion({
    required String ventaOrigenId,
    required String clienteId,
    required List<LineaDevolucionInput> lineas,
    required String motivo,
    required bool reembolsarEnEfectivo,
    String? sesionCajaId,
  }) async {
    ultimaVentaOrigenIdRegistrada = ventaOrigenId;
    ultimoClienteIdRegistrado = clienteId;
    ultimasLineasRegistradas = lineas;
    ultimoMotivoRegistrado = motivo;
    ultimoReembolsarEnEfectivo = reembolsarEnEfectivo;
    ultimaSesionCajaIdRegistrada = sesionCajaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return idADevolver;
  }

  @override
  Future<List<NotaCreditoClienteResumen>> listarNotasCreditoCliente(String clienteId, {bool soloDisponibles = false}) async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return notasARetornar;
  }

  @override
  Future<List<NotaCreditoDisponibleResumen>> listarNotasCreditoDisponibles() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return notasDisponiblesARetornar;
  }

  @override
  Future<void> reembolsarNotaCredito({required String notaCreditoId, required String sesionCajaId}) async {
    ultimaNotaCreditoIdReembolsada = notaCreditoId;
    ultimaSesionCajaIdDeReembolso = sesionCajaId;
    if (errorAforzar != null) throw Exception(errorAforzar);
  }
}
