import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/toma_inventario.dart';
import 'package:novapos_app/features/inventory/presentation/screens/ajustes_inventario_screen.dart';
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

TomaInventarioListado _toma({required String id, required EstadoTomaInventario estado}) => TomaInventarioListado(
      id: id,
      bodegaId: _bodegaA.bodegaId,
      estado: estado,
      fechaApertura: DateTime(2026, 8, 1),
      fechaCierre: null,
      cantidadLineas: 2,
    );

void main() {
  late FakeInventoryRepository fakeInventory;
  late FakeTenancyRepository fakeTenancy;

  Future<void> pumpAjustes(WidgetTester tester) async {
    fakeInventory = FakeInventoryRepository()..tomasARetornar = [_toma(id: 'toma-1', estado: EstadoTomaInventario.abierta)];
    fakeTenancy = FakeTenancyRepository()..bodegasARetornar = [_bodegaA];

    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (context, state) => const AjustesInventarioScreen()),
      GoRoute(path: '/inventario/ajustes/:id', builder: (context, state) => const Scaffold(body: Text('Detalle'))),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra el listado de Tomas de Inventario', (tester) async {
    await pumpAjustes(tester);

    expect(find.textContaining('Bodega Principal'), findsWidgets);
    expect(find.textContaining('Abierta'), findsWidgets);
  });

  testWidgets('Elegir un filtro de Bodega recarga con ese filtro', (tester) async {
    await pumpAjustes(tester);

    await tester.tap(find.byKey(const Key('filtroBodega_bodega-a')));
    await tester.pump();

    expect(fakeInventory.ultimoFiltroBodegaTomas, 'bodega-a');
  });

  testWidgets('Tocar una Toma navega al detalle', (tester) async {
    await pumpAjustes(tester);

    await tester.tap(find.byKey(const Key('toma_toma-1')));
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsOneWidget);
  });
}
