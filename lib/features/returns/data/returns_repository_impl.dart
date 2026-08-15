import '../domain/models/linea_devolucion_input.dart';
import '../domain/models/nota_credito_cliente_resumen.dart';
import '../domain/models/nota_credito_disponible_resumen.dart';
import '../domain/models/venta_confirmada_resumen.dart';
import '../domain/models/venta_para_devolucion_detalle.dart';
import '../domain/returns_repository.dart';
import 'returns_api.dart';

class ReturnsRepositoryImpl implements ReturnsRepository {
  ReturnsRepositoryImpl(this._api);

  final ReturnsApi _api;

  @override
  Future<List<VentaConfirmadaResumen>> listarVentasConfirmadas(String sucursalId) =>
      _api.listarVentasConfirmadas(sucursalId);

  @override
  Future<VentaParaDevolucionDetalle> obtenerVentaParaDevolucion(String ventaId) =>
      _api.obtenerVentaParaDevolucion(ventaId);

  @override
  Future<String> registrarDevolucion({
    required String ventaOrigenId,
    required String clienteId,
    required List<LineaDevolucionInput> lineas,
    required String motivo,
    required bool reembolsarEnEfectivo,
    String? sesionCajaId,
  }) =>
      _api.registrarDevolucion(
        ventaOrigenId: ventaOrigenId,
        clienteId: clienteId,
        lineas: lineas,
        motivo: motivo,
        reembolsarEnEfectivo: reembolsarEnEfectivo,
        sesionCajaId: sesionCajaId,
      );

  @override
  Future<List<NotaCreditoClienteResumen>> listarNotasCreditoCliente(String clienteId, {bool soloDisponibles = false}) =>
      _api.listarNotasCreditoCliente(clienteId, soloDisponibles: soloDisponibles);

  @override
  Future<List<NotaCreditoDisponibleResumen>> listarNotasCreditoDisponibles() => _api.listarNotasCreditoDisponibles();

  @override
  Future<void> reembolsarNotaCredito({required String notaCreditoId, required String sesionCajaId}) =>
      _api.reembolsarNotaCredito(notaCreditoId: notaCreditoId, sesionCajaId: sesionCajaId);
}
