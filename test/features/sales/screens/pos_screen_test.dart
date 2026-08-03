import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/sales/presentation/screens/pos_screen.dart';
import 'package:novapos_app/features/tenancy/domain/models/caja_resumen.dart';

import '../../catalog/fakes/catalog_admin_fakes.dart' show FakeCatalogAdminRepository;
import '../fakes/pos_fakes.dart';

void main() {
  late FakeCatalogRepository fakeCatalog;
  late FakeTenancyRepository fakeTenancy;
  late FakeSalesRepository fakeSales;
  late FakeInventoryRepository fakeInventory;
  late FakeCatalogAdminRepository fakeCatalogAdmin;
  late FakeCustomerRepository fakeCustomer;

  Future<void> pumpPos(
    WidgetTester tester, {
    List<CajaResumen>? cajas,
    List<Departamento>? departamentos,
  }) async {
    fakeCatalog = FakeCatalogRepository();
    fakeTenancy = FakeTenancyRepository()
      ..cajasARetornar = cajas ?? [cajaUnica]
      ..bodegaVentaARetornar = bodegaVentaFixture;
    fakeSales = FakeSalesRepository();
    fakeInventory = FakeInventoryRepository();
    fakeCatalogAdmin = FakeCatalogAdminRepository()..departamentos = departamentos ?? [];
    fakeCustomer = FakeCustomerRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        catalogAdminRepositoryProvider.overrideWithValue(fakeCatalogAdmin),
        customerRepositoryProvider.overrideWithValue(fakeCustomer),
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
    await tester.pump(); // deja resolver el Future de listarStock (si hay Bodega resuelta)
  }

  testWidgets('Con una sola Caja, la selecciona automáticamente y muestra la búsqueda', (tester) async {
    await pumpPos(tester);

    expect(find.byKey(const Key('posBusqueda')), findsOneWidget);
  });

  testWidgets('Buscar muestra los resultados y agregarlos los suma al carrito', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola, productoPan];

    await buscarYEsperar(tester, 'coca');

    expect(fakeCatalog.ultimoTexto, 'coca');
    expect(find.byKey(const Key('posResultado_variante-coca')), findsOneWidget);

    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);
    expect(find.text(r'Total: $1.500'), findsOneWidget);
  });

  testWidgets('Agregar el mismo producto dos veces suma la cantidad, no duplica la línea', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];

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
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola, productoPan];
    fakeSales.totalARetornar = 2300;

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
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.totalARetornar = 1500;

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
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.errorAforzar = 'No se pudo conectar con el servidor.';

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget, reason: 'el carrito se conserva para reintentar');
  });

  testWidgets('Quitar una línea del carrito la elimina', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];

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

  testWidgets('Muestra tabs de categoría y filtra la búsqueda por Departamento', (tester) async {
    await pumpPos(tester, departamentos: [
      const Departamento(id: 'depto-bebidas', nombre: 'Bebidas', activo: true),
    ]);

    expect(find.byKey(const Key('posCategoriaTodos')), findsOneWidget);
    expect(find.byKey(const Key('posCategoria_depto-bebidas')), findsOneWidget);

    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await tester.tap(find.byKey(const Key('posCategoria_depto-bebidas')));
    await tester.pump(const Duration(milliseconds: 400)); // pasa el debounce de la búsqueda
    await tester.pump();

    expect(fakeCatalog.ultimoDepartamentoId, 'depto-bebidas');
  });

  testWidgets('Muestra el stock de cada resultado cuando la Bodega ya se resolvió', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeInventory.stockARetornar = [const StockVariante(varianteProductoId: 'variante-coca', cantidad: 24)];

    await buscarYEsperar(tester, 'a');

    expect(fakeInventory.ultimaBodegaId, 'bodega-1');
    expect(find.textContaining('Stock 24'), findsOneWidget);
  });

  testWidgets('Sin elegir Cliente, muestra "Cliente Genérico" por defecto', (tester) async {
    await pumpPos(tester);

    expect(find.text('Cliente Genérico'), findsOneWidget);
  });

  testWidgets('Elegir un Cliente en el selector lo muestra y lo pasa al cobrar', (tester) async {
    await pumpPos(tester);
    fakeCustomer.resultadosARetornar = [clienteJuan];
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.totalARetornar = 1500;

    await tester.tap(find.byKey(const Key('posCliente')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400)); // pasa el debounce de la carga inicial
    await tester.pump(); // deja resolver el Future de buscarClientes

    await tester.tap(find.byKey(const Key('selectorClienteResultado_cliente-juan')));
    await tester.pumpAndSettle();

    expect(find.text('Juan Pérez'), findsOneWidget);

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    expect(fakeSales.ultimoClienteId, 'cliente-juan');
  });

  testWidgets('"Usar Cliente Genérico" en el selector vuelve a dejar el Cliente en null', (tester) async {
    await pumpPos(tester);
    fakeCustomer.resultadosARetornar = [clienteJuan];

    await tester.tap(find.byKey(const Key('posCliente')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(); // deja resolver el Future de buscarClientes
    await tester.tap(find.byKey(const Key('selectorClienteResultado_cliente-juan')));
    await tester.pumpAndSettle();

    expect(find.text('Juan Pérez'), findsOneWidget);

    await tester.tap(find.byKey(const Key('posCliente')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorClienteGenerico')));
    await tester.pumpAndSettle();

    expect(find.text('Cliente Genérico'), findsOneWidget);
  });
}
