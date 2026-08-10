import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/inventory/domain/models/inventory_enums.dart';
import 'package:novapos_app/features/inventory/domain/models/traslado_inventario.dart';
import 'package:novapos_app/features/inventory/presentation/screens/traslados_inventario_screen.dart';
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
const _bodegaB = BodegaResumen(
  bodegaId: 'bodega-b',
  nombreBodega: 'Bodega Norte',
  tipoBodega: TipoBodega.respaldo,
  sucursalId: 'sucursal-2',
  nombreSucursal: 'Sucursal Norte',
);

TrasladoListado _traslado() => TrasladoListado(
      id: 'traslado-1',
      bodegaOrigenId: _bodegaA.bodegaId,
      bodegaDestinoId: _bodegaB.bodegaId,
      estado: EstadoTraslado.borrador,
      fechaCreacion: DateTime(2026, 8, 1),
      fechaEnvio: null,
      fechaRecepcion: null,
      cantidadLineas: 1,
    );

void main() {
  late FakeInventoryRepository fakeInventory;
  late FakeTenancyRepository fakeTenancy;

  Future<void> pumpTraslados(WidgetTester tester) async {
    fakeInventory = FakeInventoryRepository()..trasladosARetornar = [_traslado()];
    fakeTenancy = FakeTenancyRepository()..bodegasARetornar = [_bodegaA, _bodegaB];

    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (context, state) => const TrasladosInventarioScreen()),
      GoRoute(path: '/inventario/traslados/:id', builder: (context, state) => const Scaffold(body: Text('Detalle'))),
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

  testWidgets('Muestra el listado de Traslados con origen y destino', (tester) async {
    await pumpTraslados(tester);

    expect(find.textContaining('Bodega Principal'), findsWidgets);
    expect(find.textContaining('Bodega Norte'), findsWidgets);
    expect(find.textContaining('Borrador'), findsWidgets);
  });

  testWidgets('Elegir un filtro de Bodega recarga con ese filtro', (tester) async {
    await pumpTraslados(tester);

    await tester.tap(find.byKey(const Key('filtroBodegaTraslado_bodega-b')));
    await tester.pump();

    expect(fakeInventory.ultimoFiltroBodegaTraslados, 'bodega-b');
  });

  testWidgets('Tocar un Traslado navega al detalle', (tester) async {
    await pumpTraslados(tester);

    await tester.tap(find.byKey(const Key('traslado_traslado-1')));
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsOneWidget);
  });
}
