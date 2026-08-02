import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/sales/presentation/screens/pos_screen.dart';
import 'package:novapos_app/features/tenancy/domain/models/caja_resumen.dart';

import '../fakes/pos_fakes.dart';

void main() {
  late FakeCatalogRepository fakeCatalog;
  late FakeTenancyRepository fakeTenancy;
  late FakeSalesRepository fakeSales;

  Future<void> pumpPos(WidgetTester tester, {List<CajaResumen>? cajas}) async {
    fakeCatalog = FakeCatalogRepository();
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = cajas ?? [cajaUnica];
    fakeSales = FakeSalesRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  Future<void> buscarYEsperar(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('posBusqueda')), texto);
    await tester.pump(const Duration(milliseconds: 400)); // pasa el debounce
    await tester.pump(); // deja resolver el Future de buscarProductos
  }

  testWidgets('Con una sola Caja, la selecciona automáticamente y muestra la búsqueda', (tester) async {
    await pumpPos(tester);

    expect(find.byKey(const Key('posBusqueda')), findsOneWidget);
  });

  testWidgets('Buscar muestra los resultados y agregarlos los suma al carrito', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola, productoPan];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'coca');

    expect(fakeCatalog.ultimoTexto, 'coca');
    expect(find.byKey(const Key('posResultado_variante-coca')), findsOneWidget);

    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);
    expect(find.text(r'Total: $1.500'), findsOneWidget);
  });

  testWidgets('Agregar el mismo producto dos veces suma la cantidad, no duplica la línea', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(r'Total: $3.000'), findsOneWidget);
  });

  testWidgets('Cobrar crea la Venta, agrega cada línea y confirma — luego muestra el total', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola, productoPan];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()..totalARetornar = 2300;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.ultimoCajaId, 'caja-1');
    expect(fakeSales.lineasAgregadas, hasLength(2));
    expect(fakeSales.lineasAgregadas.map((l) => l.varianteProductoId), containsAll(['variante-coca', 'variante-pan']));

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(find.text(r'Total cobrado: $2.300'), findsOneWidget);
  });

  testWidgets('Confirmar "Nueva Venta" vacía el carrito para la siguiente', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()..totalARetornar = 1500;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva Venta'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
    expect(find.text('Carrito vacío'), findsOneWidget);
  });

  testWidgets('Si crear la Venta falla, el error se muestra y el carrito NO se vacía', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()..errorAforzar = 'No se pudo conectar con el servidor.';

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget, reason: 'el carrito se conserva para reintentar');
  });

  testWidgets('Quitar una línea del carrito la elimina', (tester) async {
    fakeCatalog = FakeCatalogRepository()..resultadosARetornar = [productoCocaCola];
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: PosScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byKey(const Key('posCarrito_variante-coca')),
      matching: find.byIcon(Icons.remove_circle_outline),
    ));
    await tester.pump();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
  });

  testWidgets('El botón Cobrar está deshabilitado con el carrito vacío', (tester) async {
    await pumpPos(tester);

    final boton = tester.widget<ElevatedButton>(find.byKey(const Key('posCobrar')));
    expect(boton.onPressed, isNull);
  });
}
