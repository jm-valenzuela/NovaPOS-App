import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/sales/domain/models/estado_descuento_venta.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
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
    EscanearCodigoBarra? escanearCodigoBarra,
    bool escaneoDisponible = true,
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
      child: MaterialApp(
        home: PosScreen(
          escanearCodigoBarra: escanearCodigoBarra ?? (_) async => null,
          escaneoDisponible: escaneoDisponible,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  String textoDe(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

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
    expect(textoDe(tester, const Key('posSubtotal')), r'$1.261');
    expect(textoDe(tester, const Key('posIva')), r'$239');
    expect(textoDe(tester, const Key('posTotal')), r'$1.500');
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
    expect(textoDe(tester, const Key('posTotal')), r'$3.000');
    expect(textoDe(tester, const Key('posSubtotal')), r'$2.521');
    expect(textoDe(tester, const Key('posIva')), r'$479');
  });

  testWidgets('Cobrar crea la Venta, agrega cada línea y confirma — luego muestra el total', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola, productoPan];
    fakeSales.totalARetornar = 2300;

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    // Pan es por Kilogramo (unidadMedida: 1 en el fixture) — tocarlo abre
    // el diálogo de cantidad exacta en vez de agregarlo directo.
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '0.5');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.ultimoCajaId, 'caja-1');
    expect(fakeSales.lineasAgregadas, hasLength(2));
    expect(fakeSales.lineasAgregadas.map((l) => l.varianteProductoId), containsAll(['variante-coca', 'variante-pan']));

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(find.text(r'Total cobrado: $2.300'), findsOneWidget);
    expect(find.text(r'Subtotal: $1.933'), findsOneWidget);
    expect(find.text(r'IVA (19%): $367'), findsOneWidget);
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

  testWidgets('Escanear un código con coincidencia exacta lo agrega directo al carrito', (tester) async {
    await pumpPos(tester, escanearCodigoBarra: (_) async => productoCocaCola.codigoBarras);
    fakeCatalog.resultadosARetornar = [productoCocaCola];

    await tester.tap(find.byKey(const Key('posEscanear')));
    await tester.pumpAndSettle();

    expect(fakeCatalog.ultimoTexto, productoCocaCola.codigoBarras);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);
  });

  testWidgets('Escanear un código sin coincidencia muestra un aviso y no agrega nada', (tester) async {
    await pumpPos(tester, escanearCodigoBarra: (_) async => '0000000000000');
    fakeCatalog.resultadosARetornar = [];

    await tester.tap(find.byKey(const Key('posEscanear')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se encontró ningún producto'), findsOneWidget);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
  });

  testWidgets('Cancelar el escaneo (sin código) no agrega nada ni muestra el aviso de "no encontrado"', (tester) async {
    var vecesEscaneado = 0;
    await pumpPos(
      tester,
      escanearCodigoBarra: (_) async {
        vecesEscaneado++;
        return null;
      },
    );

    await tester.tap(find.byKey(const Key('posEscanear')));
    await tester.pumpAndSettle();

    expect(vecesEscaneado, 1);
    expect(find.textContaining('No se encontró ningún producto'), findsNothing);
    expect(find.text('Carrito vacío'), findsOneWidget);
  });

  testWidgets('Sin soporte de cámara en la plataforma (ej. Windows desktop), el botón de escanear no se muestra',
      (tester) async {
    await pumpPos(tester, escaneoDisponible: false);

    expect(find.byKey(const Key('posEscanear')), findsNothing);
  });

  testWidgets('Tocar un producto por Kilogramo abre el diálogo de cantidad y agrega el peso exacto', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoPan];

    await buscarYEsperar(tester, 'pan');
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cantidadPesable')), findsOneWidget);
    expect(find.textContaining('/kg'), findsWidgets);

    await tester.enterText(find.byKey(const Key('cantidadPesable')), '0.350');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-pan')), findsOneWidget);
    expect(find.text('0.35 kg'), findsOneWidget);
  });

  testWidgets('Cancelar el diálogo de cantidad pesable no agrega nada al carrito', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoPan];

    await buscarYEsperar(tester, 'pan');
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cantidadPesableCancelar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-pan')), findsNothing);
    expect(find.text('Carrito vacío'), findsOneWidget);
  });

  testWidgets('Tocar la cantidad de una línea pesable en el carrito permite corregirla', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoPan];

    await buscarYEsperar(tester, 'pan');
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '0.350');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    expect(find.text('0.35 kg'), findsOneWidget);

    await tester.tap(find.byKey(const Key('carritoCantidadPesable')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '0.5');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    expect(find.text('0.5 kg'), findsOneWidget);
  });

  testWidgets('Tocar la cantidad de una línea por Unidad permite tipear un número grande', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];

    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('carritoCantidadUnidad')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '2000');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    expect(find.text('2000'), findsOneWidget);
    expect(textoDe(tester, const Key('posTotal')), r'$3.000.000');
  });

  testWidgets('El diálogo de cantidad por Unidad rechaza números no enteros', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];

    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('carritoCantidadUnidad')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '2.5');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pump();

    expect(find.text('Ingresa un número entero de unidades'), findsOneWidget);
  });

  testWidgets('Un producto con promoción 2x1 muestra la etiqueta en la tarjeta', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoGaseosaPromo];

    await buscarYEsperar(tester, 'gaseosa');

    expect(find.text('2x1'), findsOneWidget);
  });

  testWidgets('Al alcanzar el grupo completo, la promoción 2x1 se aplica solo en el carrito', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoGaseosaPromo];

    await buscarYEsperar(tester, 'gaseosa');

    await tester.tap(find.byKey(const Key('posResultado_variante-gaseosa-promo')));
    await tester.pump();

    // 1 unidad, no alcanza el grupo de 2 — sin descuento.
    expect(textoDe(tester, const Key('posTotal')), r'$1.000');
    expect(find.textContaining('aplicado'), findsNothing);

    await tester.tap(find.byKey(const Key('posResultado_variante-gaseosa-promo')));
    await tester.pump();

    // 2 unidades completa el grupo: paga 1 de 2.
    expect(textoDe(tester, const Key('posTotal')), r'$1.000');
    expect(find.textContaining('2x1 aplicado'), findsOneWidget);
  });

  testWidgets('Un producto con descuento por volumen muestra el aviso en la tarjeta', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoTornillo];

    await buscarYEsperar(tester, 'tornillo');

    expect(find.textContaining('Desde 15 uds. -5%'), findsOneWidget);
  });

  testWidgets('Al alcanzar la cantidad mínima, el descuento por volumen se aplica solo en el carrito', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoTornillo];

    await buscarYEsperar(tester, 'tornillo');

    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byKey(const Key('posResultado_variante-tornillo')));
      await tester.pump();
    }

    // 14 unidades, bajo el umbral de 15 — todavía sin descuento.
    expect(textoDe(tester, const Key('posTotal')), r'$1.400');
    expect(find.textContaining('dto. por volumen aplicado'), findsNothing);

    await tester.tap(find.byKey(const Key('posResultado_variante-tornillo')));
    await tester.pump();

    // 15 unidades alcanza el umbral: 15 * 100 = 1500, con 5% de descuento = 1425.
    expect(textoDe(tester, const Key('posTotal')), r'$1.425');
    expect(find.textContaining('5% dto. por volumen aplicado'), findsOneWidget);
  });

  testWidgets('Solicitar un descuento crea la Venta, agrega las líneas y muestra el aviso de pendiente', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posDescuento')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('solicitarDescuentoValor')), '10');
    await tester.tap(find.byKey(const Key('solicitarDescuentoConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.lineasAgregadas, hasLength(1));
    expect(fakeSales.ultimoPorcentajeSolicitado, 10);
    expect(find.textContaining('pendiente de autorización'), findsOneWidget);
  });

  testWidgets('Con un descuento Pendiente, Cobrar queda deshabilitado', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posDescuento')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('solicitarDescuentoValor')), '10');
    await tester.tap(find.byKey(const Key('solicitarDescuentoConfirmar')));
    await tester.pumpAndSettle();

    final boton = tester.widget<ElevatedButton>(find.byKey(const Key('posCobrar')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Con un descuento Autorizado, muestra el monto del descuento antes del Subtotal', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posDescuento')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('solicitarDescuentoValor')), '10');
    await tester.tap(find.byKey(const Key('solicitarDescuentoConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posDescuentoAplicado')), findsNothing);

    fakeSales.estadoDescuentoARetornar = EstadoDescuentoVenta(
      ventaId: fakeSales.ventaIdARetornar,
      estado: EstadoDescuentoGeneral.autorizado,
      total: 1350,
      subtotalLineas: 1500,
      motivoRechazo: null,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byKey(const Key('posDescuentoAplicado')), findsOneWidget);
    expect(find.text('Descuento (10%)'), findsOneWidget);
    expect(textoDe(tester, const Key('posDescuentoAplicado')), '-\$150');
  });

  testWidgets('Con un descuento ya solicitado, tocar otro producto no lo agrega y avisa por qué', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola, productoPan];
    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posDescuento')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('solicitarDescuentoValor')), '10');
    await tester.tap(find.byKey(const Key('solicitarDescuentoConfirmar')));
    await tester.pumpAndSettle();

    // Pan es por Kilogramo — igual queda bloqueado el diálogo de agregar.
    await tester.tap(find.byKey(const Key('posResultado_variante-pan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cantidadPesable')), '0.5');
    await tester.tap(find.byKey(const Key('cantidadPesableConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-pan')), findsNothing);
    expect(fakeSales.lineasAgregadas, hasLength(1));
    expect(find.textContaining('No puedes agregar más productos'), findsOneWidget);
  });

  testWidgets('Vaciar con un descuento ya solicitado pide confirmación antes de borrar', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posDescuento')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('solicitarDescuentoValor')), '10');
    await tester.tap(find.byKey(const Key('solicitarDescuentoConfirmar')));
    await tester.pumpAndSettle();

    // El botón sigue habilitado (ya no se deshabilita solo por estar bloqueado).
    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Vaciar el carrito?'), findsOneWidget);

    // Cancelar: el carrito sigue igual.
    await tester.tap(find.byKey(const Key('confirmarVaciarCancelar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);

    // Confirmar: se vacía de verdad.
    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmarVaciarConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
  });

  testWidgets('Vaciar sin ningún descuento solicitado no pide confirmación', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Vaciar el carrito?'), findsNothing);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
  });
}
