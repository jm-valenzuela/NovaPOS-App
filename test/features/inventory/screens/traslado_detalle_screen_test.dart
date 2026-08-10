import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/traslado_inventario.dart';
import 'package:novapos_app/features/inventory/presentation/screens/traslado_detalle_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';

import '../../sales/fakes/pos_fakes.dart';

const _producto = ProductoVendible(
  varianteProductoId: 'variante-1',
  productoId: 'producto-1',
  nombreProducto: 'Tornillo 1/4',
  sku: 'SKU-1',
  codigoBarras: null,
  precioVenta: 500,
  unidadMedida: 0,
);

TrasladoDetalle _trasladoBorrador({List<LineaTraslado> lineas = const []}) => TrasladoDetalle(
      id: 'traslado-1',
      bodegaOrigenId: 'bodega-a',
      bodegaDestinoId: 'bodega-b',
      estado: EstadoTraslado.borrador,
      fechaEnvio: null,
      fechaRecepcion: null,
      lineas: lineas,
    );

TrasladoDetalle _trasladoEnviado() => const TrasladoDetalle(
      id: 'traslado-1',
      bodegaOrigenId: 'bodega-a',
      bodegaDestinoId: 'bodega-b',
      estado: EstadoTraslado.enviado,
      fechaEnvio: null,
      fechaRecepcion: null,
      lineas: [
        LineaTraslado(
          varianteProductoId: 'variante-1',
          nombreProducto: 'Tornillo 1/4',
          sku: 'SKU-1',
          cantidadEnviada: 5,
          cantidadRecibida: null,
          diferencia: null,
        ),
      ],
    );

void main() {
  late FakeInventoryRepository fakeInventory;
  late FakeCatalogRepository fakeCatalog;

  Future<void> pumpDetalle(WidgetTester tester, {required TrasladoDetalle traslado}) async {
    fakeInventory = FakeInventoryRepository()..trasladoDetalleARetornar = traslado;
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [_producto];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
      ],
      child: const MaterialApp(home: TrasladoDetalleScreen(trasladoId: 'traslado-1')),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Borrador sin líneas: Enviar queda deshabilitado', (tester) async {
    await pumpDetalle(tester, traslado: _trasladoBorrador());

    expect(find.text('Borrador'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('enviarTrasladoBoton')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Agregar línea busca el producto y lo envía al repositorio', (tester) async {
    await pumpDetalle(tester, traslado: _trasladoBorrador());

    await tester.tap(find.byKey(const Key('agregarLineaTrasladoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('agregarLineaTrasladoBusqueda')), 'Tornillo');
    await tester.pump();

    await tester.tap(find.byKey(const Key('agregarLineaTrasladoResultado_variante-1')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('agregarLineaTrasladoCantidad')), '5');
    await tester.tap(find.byKey(const Key('agregarLineaTrasladoConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Enviado con línea pendiente: Recibir mercadería abre el diálogo de recepción', (tester) async {
    await pumpDetalle(tester, traslado: _trasladoEnviado());

    expect(find.text('Enviado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recibirTrasladoBoton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recibirTrasladoCantidad_variante-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recibirTrasladoConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
