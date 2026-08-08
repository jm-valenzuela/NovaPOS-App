import 'package:novapos_app/features/receivables/domain/models/cliente_cobranza.dart';
import 'package:novapos_app/features/receivables/domain/models/cuenta_por_cobrar_detalle.dart';
import 'package:novapos_app/features/receivables/domain/models/movimiento_cuenta_cliente.dart';
import 'package:novapos_app/features/receivables/domain/receivables_repository.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';

class FakeReceivablesRepository implements ReceivablesRepository {
  List<ClienteCobranza> cobranzaARetornar = [];
  CuentaPorCobrarDetalle? detalleARetornar;
  String? errorAforzar;

  String? ultimoClienteIdConsultado;
  double? ultimoMontoAbonado;
  MedioPago? ultimoMedioPagoAbonado;
  String? ultimoMotivoAbonado;

  @override
  Future<List<ClienteCobranza>> listarCobranza() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return cobranzaARetornar;
  }

  @override
  Future<CuentaPorCobrarDetalle> obtenerCuenta(String clienteId) async {
    ultimoClienteIdConsultado = clienteId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return detalleARetornar!;
  }

  @override
  Future<double> registrarAbono({
    required String clienteId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) async {
    ultimoMontoAbonado = monto;
    ultimoMedioPagoAbonado = medioPago;
    ultimoMotivoAbonado = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
    final saldoRestante = (detalleARetornar?.saldoActual ?? 0) - monto;
    detalleARetornar = CuentaPorCobrarDetalle(
      clienteId: clienteId,
      nombreCliente: detalleARetornar?.nombreCliente ?? '',
      rutCliente: detalleARetornar?.rutCliente,
      saldoActual: saldoRestante,
      movimientos: [
        MovimientoCuentaCliente(
          id: 'movimiento-abono-nuevo',
          tipo: 'Abono',
          monto: monto,
          fechaVencimiento: null,
          motivo: motivo,
          medioPago: medioPago,
          fechaMovimiento: DateTime.now(),
        ),
        ...?detalleARetornar?.movimientos,
      ],
    );
    return saldoRestante;
  }
}
