import '../../sales/domain/models/venta_enums.dart';
import '../domain/models/cuenta_por_pagar_detalle.dart';
import '../domain/models/proveedor_por_pagar.dart';
import '../domain/payables_repository.dart';
import 'payables_api.dart';

class PayablesRepositoryImpl implements PayablesRepository {
  PayablesRepositoryImpl(this._api);

  final PayablesApi _api;

  @override
  Future<List<ProveedorPorPagar>> listarCuentasPorPagar() => _api.listarCuentasPorPagar();

  @override
  Future<CuentaPorPagarDetalle> obtenerCuenta(String proveedorId) => _api.obtenerCuenta(proveedorId);

  @override
  Future<double> registrarPago({
    required String proveedorId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) =>
      _api.registrarPago(proveedorId: proveedorId, monto: monto, medioPago: medioPago, motivo: motivo);
}
