import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/sales/domain/models/cotizacion.dart';
import 'package:novapos_app/features/sales/domain/models/estado_descuento_venta.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';

import '../fakes/pos_fakes.dart';

void main() {
  late FakeSalesRepository fakeSales;
  late PosCartController controller;

  setUp(() {
    fakeSales = FakeSalesRepository();
    controller = PosCartController(fakeSales);
    controller.agregarProducto(productoCocaCola, cantidad: 2);
  });

  test('solicitarDescuento crea la Venta, agrega las líneas y pide el descuento', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.lineasAgregadas, hasLength(1));
    expect(fakeSales.ultimaVentaIdDescuento, fakeSales.ventaIdARetornar);
    expect(fakeSales.ultimoPorcentajeSolicitado, 10);
    expect(fakeSales.ultimoMontoSolicitado, isNull);
    expect(controller.state.estadoDescuento, EstadoDescuentoGeneral.pendiente);
    expect(controller.state.ventaId, fakeSales.ventaIdARetornar);
  });

  test('solicitarDescuento una segunda vez reutiliza la misma Venta (no la vuelve a crear)', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    await controller.solicitarDescuento(cajaId: 'caja-1', monto: 300);

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.ultimoPorcentajeSolicitado, isNull);
    expect(fakeSales.ultimoMontoSolicitado, 300);
    expect(controller.state.descuentoMonto, 300);
  });

  test('cobrar mientras el descuento está Pendiente no confirma nada', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    await controller.cobrar(cajaId: 'caja-1');

    expect(controller.state.resumenCobrado, isNull);
    expect(controller.state.estadoDescuento, EstadoDescuentoGeneral.pendiente);
  });

  test('verificarEstadoDescuento actualiza el estado cuando ya fue Autorizado', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.autorizado,
      total: 2700,
      subtotalLineas: 3000,
      motivoRechazo: null,
    );

    await controller.verificarEstadoDescuento();

    expect(controller.state.estadoDescuento, EstadoDescuentoGeneral.autorizado);
    expect(controller.state.descuentoPorcentaje, 10);
  });

  test('verificarEstadoDescuento no hace nada mientras sigue Pendiente', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.pendiente,
      total: 3000,
      subtotalLineas: 3000,
      motivoRechazo: null,
    );

    await controller.verificarEstadoDescuento();

    expect(controller.state.estadoDescuento, EstadoDescuentoGeneral.pendiente);
  });

  test('cobrar tras un descuento Autorizado reutiliza la Venta y solo confirma', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.autorizado,
      total: 2700,
      subtotalLineas: 3000,
      motivoRechazo: null,
    );
    await controller.verificarEstadoDescuento();
    fakeSales.totalARetornar = 2700;

    await controller.cobrar(cajaId: 'caja-1');

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(controller.state.resumenCobrado, isNotNull);
  });

  test('agregarProducto no hace nada mientras el carrito está bloqueado por un descuento', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    final lineasAntes = controller.state.lineas;

    controller.agregarProducto(productoPan);

    expect(controller.state.lineas, lineasAntes);
    expect(fakeSales.lineasAgregadas, hasLength(1)); // solo la línea original, ninguna nueva
    expect(controller.state.error, isNotNull);
  });

  test('agregarProducto sigue bloqueado tras un descuento Autorizado', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);
    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.autorizado,
      total: 2700,
      subtotalLineas: 3000,
      motivoRechazo: null,
    );
    await controller.verificarEstadoDescuento();

    controller.agregarProducto(productoPan);

    expect(controller.state.lineas, hasLength(1));
  });

  test('cambiarCantidad y quitarLinea no hacen nada mientras el carrito está bloqueado', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    controller.cambiarCantidad(productoCocaCola.varianteProductoId, 5);
    controller.quitarLinea(productoCocaCola.varianteProductoId);

    expect(controller.state.lineas, hasLength(1));
    expect(controller.state.lineas.first.cantidad, 2);
  });

  test('vaciarCarrito reinicia todo el estado, no solo las líneas', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    controller.vaciarCarrito();

    expect(controller.state.lineas, isEmpty);
    expect(controller.state.ventaId, isNull);
    expect(controller.state.estadoDescuento, EstadoDescuentoGeneral.sinSolicitar);
    expect(controller.state.carritoBloqueado, isFalse);
  });

  test('montoDescuentoAplicado y totalConDescuento solo restan cuando está Autorizado', () async {
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    expect(controller.state.montoDescuentoAplicado, 0);
    expect(controller.state.totalConDescuento, controller.state.total);

    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.autorizado,
      total: 0,
      subtotalLineas: 0,
      motivoRechazo: null,
    );
    await controller.verificarEstadoDescuento();

    expect(controller.state.montoDescuentoAplicado, controller.state.total * 0.10);
  });

  test('guardarCotizacion con el carrito vacío no hace nada y devuelve null', () async {
    final controllerVacio = PosCartController(fakeSales);

    final resultado = await controllerVacio.guardarCotizacion(cajaId: 'caja-1');

    expect(resultado, isNull);
    expect(fakeSales.vecesCrearLlamado, 0);
  });

  test('guardarCotizacion crea la Venta, agrega las líneas, marca como cotización y vacía el carrito', () async {
    fakeSales.ventaIdARetornar = 'venta-cotizacion-1';

    final resultado = await controller.guardarCotizacion(cajaId: 'caja-1', clienteId: 'cliente-juan');

    expect(resultado, 'venta-cotizacion-1');
    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.ultimoClienteId, 'cliente-juan');
    expect(fakeSales.lineasAgregadas, hasLength(1));
    expect(fakeSales.ultimaVentaIdMarcadaCotizacion, 'venta-cotizacion-1');
    expect(controller.state.lineas, isEmpty);
    expect(controller.state.ventaId, isNull);
  });

  test('guardarCotizacion reusa la Venta si ya existía (ej. tras solicitar un descuento)', () async {
    fakeSales.ventaIdARetornar = 'venta-existente';
    await controller.solicitarDescuento(cajaId: 'caja-1', porcentaje: 10);

    final resultado = await controller.guardarCotizacion(cajaId: 'caja-1');

    expect(resultado, 'venta-existente');
    expect(fakeSales.vecesCrearLlamado, 1, reason: 'no debe crear una segunda Venta si ya existía');
    expect(fakeSales.ultimaVentaIdMarcadaCotizacion, 'venta-existente');
  });

  test('guardarCotizacion informa el error y no vacía el carrito si falla', () async {
    fakeSales.errorAforzar = 'fallo de red';

    final resultado = await controller.guardarCotizacion(cajaId: 'caja-1');

    expect(resultado, isNull);
    expect(controller.state.error, contains('fallo de red'));
    expect(controller.state.lineas, isNotEmpty);
    expect(controller.state.procesandoCotizacion, isFalse);
  });

  test('rescatarCotizacion trae el detalle y reemplaza el carrito, con la Venta bloqueada', () async {
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-rescatada',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      total: 3000,
      lineas: [
        LineaCotizacionDetalle(
          varianteProductoId: 'variante-coca',
          nombreProducto: 'Coca Cola 1.5L',
          sku: 'COCA-15',
          cantidad: 2,
          precioUnitario: 1500,
          subtotal: 3000,
        ),
      ],
    );

    final detalle = await controller.rescatarCotizacion('venta-rescatada');

    expect(detalle?.clienteNombre, 'Juan Pérez');
    expect(fakeSales.ultimaVentaIdCotizacionConsultada, 'venta-rescatada');
    expect(controller.state.ventaId, 'venta-rescatada');
    expect(controller.state.carritoBloqueado, isTrue);
    expect(controller.state.lineas, hasLength(1));
    expect(controller.state.lineas.first.cantidad, 2);
    expect(controller.state.total, 3000);
  });

  test('rescatarCotizacion informa el error si falla la consulta', () async {
    fakeSales.errorAforzar = 'no encontrada';

    final detalle = await controller.rescatarCotizacion('venta-x');

    expect(detalle, isNull);
    expect(controller.state.error, contains('no encontrada'));
  });
}
