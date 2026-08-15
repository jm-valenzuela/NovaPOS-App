import '../domain/customer_repository.dart';
import '../domain/models/cliente_resumen.dart';
import '../domain/models/plazo_pago.dart';
import '../domain/models/solicitud_credito_pendiente.dart';
import 'customer_api.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._api);

  final CustomerApi _api;

  @override
  Future<List<ClienteResumen>> buscarClientes({String? texto}) => _api.buscarClientes(texto: texto);

  @override
  Future<String> crearCliente({
    required String nombre,
    String? rut,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) =>
      _api.crearCliente(
        nombre: nombre,
        rut: rut,
        email: email,
        telefono: telefono,
        cupoCredito: cupoCredito,
        plazoPagoId: plazoPagoId,
        giro: giro,
        direccion: direccion,
        comuna: comuna,
        ciudad: ciudad,
      );

  @override
  Future<void> actualizarCliente({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    String? plazoPagoId,
    String? giro,
    String? direccion,
    String? comuna,
    String? ciudad,
  }) =>
      _api.actualizarCliente(
        clienteId: clienteId,
        nombre: nombre,
        email: email,
        telefono: telefono,
        cupoCredito: cupoCredito,
        plazoPagoId: plazoPagoId,
        giro: giro,
        direccion: direccion,
        comuna: comuna,
        ciudad: ciudad,
      );

  @override
  Future<void> asignarRutCliente({required String clienteId, required String rut}) =>
      _api.asignarRutCliente(clienteId: clienteId, rut: rut);

  @override
  Future<void> solicitarCreditoCliente({
    required String clienteId,
    required double cupoSolicitado,
    String? plazoPagoIdSolicitado,
    String? observacion,
  }) =>
      _api.solicitarCreditoCliente(
        clienteId: clienteId,
        cupoSolicitado: cupoSolicitado,
        plazoPagoIdSolicitado: plazoPagoIdSolicitado,
        observacion: observacion,
      );

  @override
  Future<void> autorizarCreditoCliente(String clienteId) => _api.autorizarCreditoCliente(clienteId);

  @override
  Future<void> rechazarCreditoCliente({required String clienteId, required String motivo}) =>
      _api.rechazarCreditoCliente(clienteId: clienteId, motivo: motivo);

  @override
  Future<List<SolicitudCreditoPendiente>> listarSolicitudesCreditoPendientes() => _api.listarSolicitudesCreditoPendientes();

  @override
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas}) =>
      _api.crearPlazoPago(nombre: nombre, diasCuotas: diasCuotas);

  @override
  Future<List<PlazoPago>> listarPlazosPago() => _api.listarPlazosPago();

  @override
  Future<void> activarPlazoPago(String plazoPagoId) => _api.activarPlazoPago(plazoPagoId);

  @override
  Future<void> desactivarPlazoPago(String plazoPagoId) => _api.desactivarPlazoPago(plazoPagoId);
}
