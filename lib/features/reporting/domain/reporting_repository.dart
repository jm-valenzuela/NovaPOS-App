import 'models/flujo_caja_dia.dart';

/// Contrato de Reporting consumido por el frontend — por ahora solo
/// Flujo de Caja; el backend ya expone otros reportes (ventas-por-dia,
/// stock-valorizado, compras-por-proveedor, cuentas-por-cobrar/pagar,
/// cobranza) sin consumo en el cliente todavía.
abstract class ReportingRepository {
  Future<List<FlujoCajaDia>> obtenerFlujoCaja({required DateTime desde, required DateTime hasta});
}
