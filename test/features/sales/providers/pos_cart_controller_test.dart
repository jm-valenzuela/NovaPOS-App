import 'package:flutter_test/flutter_test.dart';

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
}
