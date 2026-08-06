import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/purchasing/domain/models/orden_compra.dart';
import 'package:novapos_app/features/purchasing/domain/models/purchasing_enums.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/orden_compra_detalle_screen.dart';

import '../fakes/purchasing_fakes.dart';

const _lineaPendiente = LineaOrdenCompra(
  varianteProductoId: 'variante-1',
  nombreProducto: 'Aceite de Motor 5W-30',
  sku: 'DEMO-ACEITE',
  cantidad: 10,
  costoUnitario: 5000,
  cantidadRecibida: 0,
  cantidadPendiente: 10,
);

Future<void> _pumpDetalle(WidgetTester tester, FakePurchasingRepository fake, {required EstadoOrdenCompra estado}) async {
  fake.ordenDetalleARetornar = OrdenCompraDetalle(
    id: 'orden-1',
    proveedorId: 'proveedor-1',
    bodegaDestinoId: 'bodega-1',
    formaPago: FormaPago.contado,
    estado: estado,
    total: 50000,
    fechaEnvio: estado == EstadoOrdenCompra.borrador ? null : DateTime(2026, 8, 1),
    fechaRecepcion: null,
    lineas: const [_lineaPendiente],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [purchasingRepositoryProvider.overrideWithValue(fake)],
    child: const MaterialApp(home: OrdenCompraDetalleScreen(ordenCompraId: 'orden-1')),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  late FakePurchasingRepository fakePurchasing;

  setUp(() {
    fakePurchasing = FakePurchasingRepository();
  });

  testWidgets('En Borrador muestra Agregar línea y Enviar, no Recibir', (tester) async {
    await _pumpDetalle(tester, fakePurchasing, estado: EstadoOrdenCompra.borrador);

    expect(find.byKey(const Key('agregarLineaBoton')), findsOneWidget);
    expect(find.byKey(const Key('enviarOrdenBoton')), findsOneWidget);
    expect(find.byKey(const Key('recibirOrdenBoton')), findsNothing);
    expect(find.text('Aceite de Motor 5W-30'), findsOneWidget);
  });

  testWidgets('En Enviada muestra Recibir, no Agregar línea ni Enviar', (tester) async {
    await _pumpDetalle(tester, fakePurchasing, estado: EstadoOrdenCompra.enviada);

    expect(find.byKey(const Key('agregarLineaBoton')), findsNothing);
    expect(find.byKey(const Key('enviarOrdenBoton')), findsNothing);
    expect(find.byKey(const Key('recibirOrdenBoton')), findsOneWidget);
  });

  testWidgets('En Recibida no muestra ningún botón de acción', (tester) async {
    await _pumpDetalle(tester, fakePurchasing, estado: EstadoOrdenCompra.recibida);

    expect(find.byKey(const Key('agregarLineaBoton')), findsNothing);
    expect(find.byKey(const Key('enviarOrdenBoton')), findsNothing);
    expect(find.byKey(const Key('recibirOrdenBoton')), findsNothing);
  });

  testWidgets('Enviar llama a enviarOrdenCompra', (tester) async {
    await _pumpDetalle(tester, fakePurchasing, estado: EstadoOrdenCompra.borrador);

    await tester.tap(find.byKey(const Key('enviarOrdenBoton')));
    await tester.pump();

    expect(fakePurchasing.enviarLlamado, isTrue);
  });

  testWidgets('Recibir abre el diálogo con la línea pendiente y confirma la cantidad', (tester) async {
    await _pumpDetalle(tester, fakePurchasing, estado: EstadoOrdenCompra.enviada);

    await tester.tap(find.byKey(const Key('recibirOrdenBoton')));
    await tester.pumpAndSettle();

    expect(find.text('Aceite de Motor 5W-30 (pendiente: 10)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('recibirConfirmar')));
    await tester.pumpAndSettle();

    expect(fakePurchasing.ultimasLineasRecibidas, {'variante-1': 10.0});
  });
}
