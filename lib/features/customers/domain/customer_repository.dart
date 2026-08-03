import 'models/cliente_resumen.dart';

abstract class CustomerRepository {
  Future<List<ClienteResumen>> buscarClientes({String? texto});
}
