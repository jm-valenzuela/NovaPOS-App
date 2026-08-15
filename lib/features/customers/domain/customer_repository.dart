import 'models/cliente_resumen.dart';
import 'models/plazo_pago.dart';
import 'models/solicitud_credito_pendiente.dart';

abstract class CustomerRepository {
  Future<List<ClienteResumen>> buscarClientes({String? texto});

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
  });

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
  });

  /// Completa el Rut de un Cliente que quedó sin uno (ej. creado antes de que el alta lo exigiera) — falla si ya tiene uno.
  Future<void> asignarRutCliente({required String clienteId, required String rut});

  /// Dispara la evaluación de Cupo de Crédito — no lo otorga de inmediato, ver ClientesAdminScreen.
  Future<void> solicitarCreditoCliente({
    required String clienteId,
    required double cupoSolicitado,
    String? plazoPagoIdSolicitado,
    String? observacion,
  });

  Future<void> autorizarCreditoCliente(String clienteId);

  Future<void> rechazarCreditoCliente({required String clienteId, required String motivo});

  /// Cola de trabajo de quien autoriza Cupo de Crédito — ver "customers.clientes.autorizarcredito".
  Future<List<SolicitudCreditoPendiente>> listarSolicitudesCreditoPendientes();

  // Catálogo de Plazos de Pago — ver PlazoPagoScreen.
  Future<String> crearPlazoPago({required String nombre, required List<int> diasCuotas});

  Future<List<PlazoPago>> listarPlazosPago();

  Future<void> activarPlazoPago(String plazoPagoId);

  Future<void> desactivarPlazoPago(String plazoPagoId);
}
