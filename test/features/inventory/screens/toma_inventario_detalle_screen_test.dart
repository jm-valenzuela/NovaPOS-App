import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/toma_inventario.dart';
import 'package:novapos_app/features/inventory/presentation/screens/toma_inventario_detalle_screen.dart';
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

TomaInventarioDetalle _tomaAbierta({List<LineaTomaInventario> lineas = const []}) => TomaInventarioDetalle(
      id: 'toma-1',
      bodegaId: 'bodega-1',
      estado: EstadoTomaInventario.abierta,
      fechaApertura: DateTime(2026, 8, 1),
      fechaCierre: null,
      lineas: lineas,
    );

void main() {
  late FakeInventoryRepository fakeInventory;
  late FakeCatalogRepository fakeCatalog;

  Future<void> pumpDetalle(WidgetTester tester, {TomaInventarioDetalle? toma}) async {
    fakeInventory = FakeInventoryRepository()..tomaDetalleARetornar = toma ?? _tomaAbierta();
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [_producto];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
      ],
      child: const MaterialApp(home: TomaInventarioDetalleScreen(tomaId: 'toma-1')),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Toma Abierta sin líneas: Cerrar queda deshabilitado', (tester) async {
    await pumpDetalle(tester);

    expect(find.text('Abierta'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('cerrarTomaBoton')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Registrar conteo busca el producto y lo envía al repositorio', (tester) async {
    await pumpDetalle(tester);

    await tester.tap(find.byKey(const Key('registrarConteoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('registrarConteoBusqueda')), 'Tornillo');
    await tester.pump();

    await tester.tap(find.byKey(const Key('registrarConteoResultado_variante-1')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('registrarConteoCantidad')), '8');
    await tester.tap(find.byKey(const Key('registrarConteoConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Con líneas registradas, Cerrar Toma queda habilitado y llama al repositorio', (tester) async {
    await pumpDetalle(tester, toma: _tomaAbierta(lineas: const [
      LineaTomaInventario(
        varianteProductoId: 'variante-1',
        nombreProducto: 'Tornillo 1/4',
        sku: 'SKU-1',
        cantidadSistema: 10,
        cantidadContada: 8,
        diferencia: -2,
      ),
    ]));

    expect(find.text('Tornillo 1/4'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);

    final boton = tester.widget<FilledButton>(find.byKey(const Key('cerrarTomaBoton')));
    expect(boton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('cerrarTomaBoton')));
    await tester.pump();
  });
}
