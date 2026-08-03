import '../domain/customer_repository.dart';
import '../domain/models/cliente_resumen.dart';
import 'customer_api.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._api);

  final CustomerApi _api;

  @override
  Future<List<ClienteResumen>> buscarClientes({String? texto}) => _api.buscarClientes(texto: texto);
}
