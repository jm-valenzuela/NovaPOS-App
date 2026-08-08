import '../../sales/domain/models/venta_enums.dart';
import '../domain/models/cliente_cobranza.dart';
import '../domain/models/cuenta_por_cobrar_detalle.dart';
import '../domain/receivables_repository.dart';
import 'receivables_api.dart';

class ReceivablesRepositoryImpl implements ReceivablesRepository {
  ReceivablesRepositoryImpl(this._api);

  final ReceivablesApi _api;

  @override
  Future<List<ClienteCobranza>> listarCobranza() => _api.listarCobranza();

  @override
  Future<CuentaPorCobrarDetalle> obtenerCuenta(String clienteId) => _api.obtenerCuenta(clienteId);

  @override
  Future<double> registrarAbono({
    required String clienteId,
    required double monto,
    required MedioPago medioPago,
    String? motivo,
  }) =>
      _api.registrarAbono(clienteId: clienteId, monto: monto, medioPago: medioPago, motivo: motivo);
}
