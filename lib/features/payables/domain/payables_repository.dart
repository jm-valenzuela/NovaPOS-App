import '../../sales/domain/models/venta_enums.dart';
import 'models/cuenta_por_pagar_detalle.dart';
import 'models/proveedor_por_pagar.dart';

/// Contrato de Cuentas por Pagar — listado global de Proveedores con saldo
/// pendiente, detalle de la Cuenta de un Proveedor puntual, y registrar Pagos.
abstract class PayablesRepository {
  Future<List<ProveedorPorPagar>> listarCuentasPorPagar();

  Future<CuentaPorPagarDetalle> obtenerCuenta(String proveedorId);

  Future<double> registrarPago({
    required String proveedorId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  });
}
