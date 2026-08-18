import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart'
    show catalogRepositoryProvider, inventoryRepositoryProvider;
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/widgets/editor_item_orden_trabajo_dialog.dart';

import '../../sales/fakes/pos_fakes.dart';
import '../fakes/workorders_fakes.dart';

final _productoEnOferta = ProductoVendible(
  varianteProductoId: 'variante-1',
  productoId: 'producto-1',
  nombreProducto: 'Aceite de Motor 5W-30',
  sku: 'ACE-5W30',
  codigoBarras: null,
  precioVenta: 12000,
  unidadMedida: 0,
  precioOferta: 9000,
  ofertaDesde: DateTime.now().subtract(const Duration(days: 1)),
  ofertaHasta: DateTime.now().add(const Duration(days: 1)),
);

void main() {
  late FakeWorkOrdersRepository fake;

  Future<void> abrirDialogo(WidgetTester tester, {String? itemIdACotizar, String? descripcionExistente}) async {
    fake = FakeWorkOrdersRepository();
    final catalog = FakeCatalogRepository()..resultadosARetornar = [_productoEnOferta];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        workOrdersRepositoryProvider.overrideWithValue(fake),
        catalogRepositoryProvider.overrideWithValue(catalog),
        inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => EditorItemOrdenTrabajoDialog(
                ordenTrabajoId: 'ot-1',
                itemIdACotizar: itemIdACotizar,
                descripcionExistente: descripcionExistente,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Agregar Ítem sin líneas queda Pendiente de evaluación', (tester) async {
    await abrirDialogo(tester);

    await tester.enterText(find.byKey(const Key('editorItemDescripcion')), 'Ruido en tren delantero');
    await tester.tap(find.byKey(const Key('editorItemGuardar')));
    await tester.pump();
    await tester.pump();

    expect(fake.ultimaDescripcion, 'Ruido en tren delantero');
    expect(fake.ultimasLineas, isNull);
  });

  testWidgets('Agregar Ítem con una línea de Trabajo lo manda cotizado directo', (tester) async {
    await abrirDialogo(tester);

    await tester.enterText(find.byKey(const Key('editorItemDescripcion')), 'Cambio de aceite');
    await tester.tap(find.byKey(const Key('editorItemAgregarTrabajo')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('editorItemTrabajoDescripcion_0')), 'Mano de obra');
    await tester.enterText(find.byKey(const Key('editorItemTrabajoMonto_0')), '25000');
    await tester.tap(find.byKey(const Key('editorItemGuardar')));
    await tester.pump();
    await tester.pump();

    expect(fake.ultimasLineas, hasLength(1));
    expect(fake.ultimasLineas!.first.monto, 25000);
  });

  testWidgets('Cotizar un Ítem existente exige al menos una línea', (tester) async {
    await abrirDialogo(tester, itemIdACotizar: 'item-1', descripcionExistente: 'Ruido en la suspensión');

    await tester.tap(find.byKey(const Key('editorItemGuardar')));
    await tester.pump();

    expect(find.textContaining('Agrega al menos una línea'), findsOneWidget);
  });

  testWidgets('El buscador de Línea de Producto muestra la tarjeta del POS, con Oferta visible', (tester) async {
    await abrirDialogo(tester);

    await tester.tap(find.byKey(const Key('editorItemAgregarProducto')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('editorItemBusquedaProducto')), 'aceite');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aceite de Motor 5W-30'), findsOneWidget);
    expect(find.text('Oferta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editorItemProducto_variante-1')));
    await tester.pump();

    expect(find.byKey(const Key('editorItemCantidadProducto_0')), findsOneWidget);
  });
}
