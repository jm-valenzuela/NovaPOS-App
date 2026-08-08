import '../../sales/domain/models/venta_enums.dart';
import 'models/cliente_cobranza.dart';
import 'models/cuenta_por_cobrar_detalle.dart';

/// Contrato de Cobranzas — listado global de Clientes con saldo pendiente,
/// detalle de la Cuenta de un Cliente puntual, y registrar Abonos.
abstract class ReceivablesRepository {
  Future<List<ClienteCobranza>> listarCobranza();

  Future<CuentaPorCobrarDetalle> obtenerCuenta(String clienteId);

  Future<double> registrarAbono({
    required String clienteId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  });
}
