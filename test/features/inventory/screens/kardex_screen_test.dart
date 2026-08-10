import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_vendible.dart';
import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/tarjeta_existencia.dart';
import 'package:novapos_app/features/inventory/presentation/screens/kardex_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/tenancy/domain/models/bodega_resumen.dart';

import '../../sales/fakes/pos_fakes.dart';

const _bodegaA = BodegaResumen(
  bodegaId: 'bodega-a',
  nombreBodega: 'Bodega Principal',
  tipoBodega: TipoBodega.venta,
  sucursalId: 'sucursal-1',
  nombreSucursal: 'Casa Matriz',
);

const _producto = ProductoVendible(
  varianteProductoId: 'variante-1',
  productoId: 'producto-1',
  nombreProducto: 'Tornillo 1/4',
  sku: 'SKU-1',
  codigoBarras: null,
  precioVenta: 500,
  unidadMedida: 0,
);

void main() {
  late FakeInventoryRepository fakeInventory;
  late FakeCatalogRepository fakeCatalog;
  late FakeTenancyRepository fakeTenancy;

  Future<void> pumpKardex(WidgetTester tester) async {
    fakeInventory = FakeInventoryRepository()
      ..tarjetaExistenciaARetornar = [
        LineaTarjetaExistencia(
          fechaMovimiento: DateTime(2026, 8, 1),
          tipo: TipoMovimientoInventario.entrada,
          cantidad: 10,
          motivo: 'Compra',
          saldoAcumulado: 10,
        ),
      ];
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [_producto];
    fakeTenancy = FakeTenancyRepository()..bodegasARetornar = [_bodegaA];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
      ],
      child: const MaterialApp(home: KardexScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Sin Bodega/Producto elegidos, Consultar está deshabilitado', (tester) async {
    await pumpKardex(tester);

    final boton = tester.widget<FilledButton>(find.byKey(const Key('kardexConsultar')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Elegir Bodega y Producto y consultar muestra los movimientos', (tester) async {
    await pumpKardex(tester);

    await tester.tap(find.byKey(const Key('kardexBodega')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bodega Principal (Casa Matriz)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('kardexBusquedaProducto')), 'Tornillo');
    await tester.pump();
    await tester.tap(find.byKey(const Key('kardexResultado_variante-1')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('kardexConsultar')));
    await tester.pump();

    expect(find.textContaining('Entrada: 10'), findsOneWidget);
    expect(find.textContaining('Saldo: 10'), findsOneWidget);
  });
}
