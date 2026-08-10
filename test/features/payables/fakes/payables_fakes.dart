import 'package:novapos_app/features/payables/domain/models/cuenta_por_pagar_detalle.dart';
import 'package:novapos_app/features/payables/domain/models/movimiento_cuenta_proveedor.dart';
import 'package:novapos_app/features/payables/domain/models/proveedor_por_pagar.dart';
import 'package:novapos_app/features/payables/domain/payables_repository.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';

class FakePayablesRepository implements PayablesRepository {
  List<ProveedorPorPagar> cuentasPorPagarARetornar = [];
  CuentaPorPagarDetalle? detalleARetornar;
  String? errorAforzar;

  String? ultimoProveedorIdConsultado;
  double? ultimoMontoPagado;
  MedioPago? ultimoMedioPagoPagado;
  String? ultimoMotivoPagado;

  @override
  Future<List<ProveedorPorPagar>> listarCuentasPorPagar() async {
    if (errorAforzar != null) throw Exception(errorAforzar);
    return cuentasPorPagarARetornar;
  }

  @override
  Future<CuentaPorPagarDetalle> obtenerCuenta(String proveedorId) async {
    ultimoProveedorIdConsultado = proveedorId;
    if (errorAforzar != null) throw Exception(errorAforzar);
    return detalleARetornar!;
  }

  @override
  Future<double> registrarPago({
    required String proveedorId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) async {
    ultimoMontoPagado = monto;
    ultimoMedioPagoPagado = medioPago;
    ultimoMotivoPagado = motivo;
    if (errorAforzar != null) throw Exception(errorAforzar);
    final saldoRestante = (detalleARetornar?.saldoActual ?? 0) - monto;
    detalleARetornar = CuentaPorPagarDetalle(
      proveedorId: proveedorId,
      nombreProveedor: detalleARetornar?.nombreProveedor ?? '',
      rutProveedor: detalleARetornar?.rutProveedor,
      saldoActual: saldoRestante,
      movimientos: [
        MovimientoCuentaProveedor(
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
