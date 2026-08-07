import '../domain/customer_repository.dart';
import '../domain/models/cliente_resumen.dart';
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
    int plazoPagoDias = 0,
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
        plazoPagoDias: plazoPagoDias,
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
    int plazoPagoDias = 0,
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
        plazoPagoDias: plazoPagoDias,
        giro: giro,
        direccion: direccion,
        comuna: comuna,
        ciudad: ciudad,
      );

  @override
  Future<void> asignarRutCliente({required String clienteId, required String rut}) =>
      _api.asignarRutCliente(clienteId: clienteId, rut: rut);
}
