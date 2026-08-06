import 'models/cliente_resumen.dart';

abstract class CustomerRepository {
  Future<List<ClienteResumen>> buscarClientes({String? texto});

  Future<String> crearCliente({
    required String nombre,
    String? rut,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    int plazoPagoDias = 0,
  });

  Future<void> actualizarCliente({
    required String clienteId,
    required String nombre,
    String? email,
    String? telefono,
    double cupoCredito = 0,
    int plazoPagoDias = 0,
  });
}
