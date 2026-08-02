import '../domain/models/venta_enums.dart';
import '../domain/sales_repository.dart';
import 'venta_api.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._api);

  final VentaApi _api;

  @override
  Future<String> crearVenta({required String cajaId, String? clienteId}) => _api.crear(
        cajaId: cajaId,
        clienteId: clienteId,
        formaPago: FormaPago.contado,
        tipoEntrega: TipoEntrega.inmediata,
      );

  @override
  Future<void> agregarLinea({required String ventaId, required String varianteProductoId, required double cantidad}) =>
      _api.agregarLinea(ventaId: ventaId, varianteProductoId: varianteProductoId, cantidad: cantidad);

  @override
  Future<double> confirmarVenta(String ventaId) => _api.confirmar(ventaId);
}
