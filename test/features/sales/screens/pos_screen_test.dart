import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/cash/domain/models/resumen_cierre_caja.dart';
import 'package:novapos_app/features/cash/domain/models/sesion_caja.dart';
import 'package:novapos_app/features/cash/presentation/providers/cash_providers.dart';
import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/domain/models/unidad_medida.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/inventory/domain/models/stock_variante.dart';
import 'package:novapos_app/features/returns/domain/models/nota_credito_disponible_resumen.dart';
import 'package:novapos_app/features/returns/presentation/providers/returns_providers.dart';
import 'package:novapos_app/features/sales/domain/models/cotizacion.dart';
import 'package:novapos_app/features/sales/domain/models/estado_descuento_venta.dart';
import 'package:novapos_app/features/sales/domain/models/resumen_venta.dart';
import 'package:novapos_app/features/sales/domain/models/stock_insuficiente_exception.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/sales/presentation/screens/pos_screen.dart';
import 'package:novapos_app/features/tenancy/domain/models/caja_resumen.dart';

import '../../cash/fakes/cash_fakes.dart';
import '../../catalog/fakes/catalog_admin_fakes.dart' show FakeCatalogAdminRepository;
import '../../returns/fakes/returns_fakes.dart';
import '../fakes/pos_fakes.dart';

/// Sentinel para distinguir "no pasé el parámetro" de "pasé null a propósito"
/// en `sesionCajaAbierta` (que es un `SesionCaja?`).
const _sinEspecificar = Object();

void main() {
  late FakeCatalogRepository fakeCatalog;
  late FakeTenancyRepository fakeTenancy;
  late FakeSalesRepository fakeSales;
  late FakeInventoryRepository fakeInventory;
  late FakeCatalogAdminRepository fakeCatalogAdmin;
  late FakeCustomerRepository fakeCustomer;
  late FakeCashRepository fakeCash;
  late FakeReturnsRepository fakeReturns;

  /// Por defecto la Caja ya tiene una Sesión Abierta — así el grueso de los
  /// tests de este archivo (que no tienen relación con Cash) no interactúa
  /// con el diálogo bloqueante de "Abrir Caja". Los tests que sí prueban el
  /// flujo de Caja pasan `sesionCajaAbierta: null` explícito.
  Future<void> pumpPos(
    WidgetTester tester, {
    List<CajaResumen>? cajas,
    List<Departamento>? departamentos,
    EscanearCodigoBarra? escanearCodigoBarra,
    bool escaneoDisponible = true,
    Object? sesionCajaAbierta = _sinEspecificar,
  }) async {
    fakeCatalog = FakeCatalogRepository();
    fakeTenancy = FakeTenancyRepository()
      ..cajasARetornar = cajas ?? [cajaUnica]
      ..bodegaVentaARetornar = bodegaVentaFixture;
    fakeSales = FakeSalesRepository();
    fakeInventory = FakeInventoryRepository();
    fakeCatalogAdmin = FakeCatalogAdminRepository()..departamentos = departamentos ?? [];
    fakeCustomer = FakeCustomerRepository();
    fakeReturns = FakeReturnsRepository();
    fakeCash = FakeCashRepository()
      ..sesionAbiertaARetornar = identical(sesionCajaAbierta, _sinEspecificar)
          ? SesionCaja(
              id: 'sesion-1',
              cajaId: cajaUnica.cajaId,
              montoInicial: 20000,
              abiertaPorUsuarioId: 'usuario-1',
              fechaApertura: DateTime(2026, 8, 11),
              estado: EstadoSesionCaja.abierta,
            )
          : sesionCajaAbierta as SesionCaja?;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(fakeCatalog),
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
        inventoryRepositoryProvider.overrideWithValue(fakeInventory),
        catalogAdminRepositoryProvider.overrideWithValue(fakeCatalogAdmin),
        customerRepositoryProvider.overrideWithValue(fakeCustomer),
        cashRepositoryProvider.overrideWithValue(fakeCash),
        returnsRepositoryProvider.overrideWithValue(fakeReturns),
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

  /// Toca "Cobrar", que ahora abre CheckoutDialog (Boleta por defecto,
  /// Contado siempre pide medio de pago) — completa un único pago en
  /// Efectivo por el Total exacto del carrito y confirma.
  Future<void> cobrarConfirmando(WidgetTester tester, double totalCarrito) async {
    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), totalCarrito.toStringAsFixed(0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkoutConfirmar')));
    await tester.pumpAndSettle();
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

    await cobrarConfirmando(tester, 1900); // 1500 (coca) + 400 (0.5kg de pan a $800)

    expect(fakeSales.vecesCrearLlamado, 1);
    expect(fakeSales.ultimoCajaId, 'caja-1');
    expect(fakeSales.lineasAgregadas, hasLength(2));
    expect(fakeSales.lineasAgregadas.map((l) => l.varianteProductoId), containsAll(['variante-coca', 'variante-pan']));

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(find.text(r'Total cobrado: $2.300'), findsOneWidget);
    expect(find.text(r'Subtotal: $1.933'), findsOneWidget);
    expect(find.text(r'IVA (19%): $367'), findsOneWidget);
    // El fake no devuelve datos de DTE por defecto — se avisa en vez de
    // ofrecer un botón "Imprimir" que fallaría sin Folio/TED.
    expect(find.byKey(const Key('ventaConfirmadaSinDte')), findsOneWidget);
    expect(find.byKey(const Key('ventaConfirmadaImprimir')), findsNothing);
  });

  testWidgets('Con stock insuficiente muestra la advertencia y "Cancelar" no confirma la Venta', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.stockInsuficienteAForzar = const StockInsuficienteException(
      'Stock insuficiente para: Coca-Cola (hay 0, pediste 1)',
      [LineaSinStockSuficiente(nombreProducto: 'Coca-Cola', cantidadDisponible: 0, cantidadPedida: 1)],
    );

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await cobrarConfirmando(tester, 1500);

    expect(find.text('Stock insuficiente'), findsOneWidget);
    expect(find.textContaining('Coca-Cola: hay 0, pediste 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stockInsuficienteCancelar')));
    await tester.pumpAndSettle();

    expect(find.text('Venta confirmada'), findsNothing);
    expect(fakeSales.ultimoPermitirVentaSinStock, isFalse);
  });

  testWidgets('Con stock insuficiente, "Continuar de todas formas" reintenta con permitirVentaSinStock', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.stockInsuficienteAForzar = const StockInsuficienteException(
      'Stock insuficiente para: Coca-Cola (hay 0, pediste 1)',
      [LineaSinStockSuficiente(nombreProducto: 'Coca-Cola', cantidadDisponible: 0, cantidadPedida: 1)],
    );

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await cobrarConfirmando(tester, 1500);

    await tester.tap(find.byKey(const Key('stockInsuficienteContinuar')));
    await tester.pumpAndSettle();

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(fakeSales.ultimoPermitirVentaSinStock, isTrue);
  });

  testWidgets('Cuando el backend emitió el DTE, "Venta confirmada" ofrece Imprimir con el Folio', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.resumenConfirmarARetornar = const ResumenVenta(
      neto: 1261,
      iva: 239,
      total: 1500,
      dteEmitidoId: 'dte-1',
      tipoDocumentoEmitido: 39,
      folio: 8,
      rutEmisor: '81814677-9',
      razonSocialEmisor: 'NovaPOS Demo SpA',
      rutReceptor: '66666666-6',
      razonSocialReceptor: 'Cliente Genérico',
      ted: '<TED>...</TED>',
    );

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await cobrarConfirmando(tester, 1500);

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(find.text('Folio 8'), findsOneWidget);
    expect(find.byKey(const Key('ventaConfirmadaImprimir')), findsOneWidget);
    expect(find.byKey(const Key('ventaConfirmadaSinDte')), findsNothing);
  });

  testWidgets('Cobrar en Efectivo por sobre el Total muestra el Vuelto en "Venta confirmada"', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.totalARetornar = 1500;

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('posCobrar')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '2000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkoutConfirmar')));
    await tester.pumpAndSettle();

    expect(find.text('Venta confirmada'), findsOneWidget);
    expect(find.byKey(const Key('ventaConfirmadaVuelto')), findsOneWidget);
    expect(find.text(r'Vuelto: $500'), findsOneWidget);
  });

  testWidgets('Confirmar "Nueva Venta" vacía el carrito para la siguiente', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    fakeSales.totalARetornar = 1500;

    await buscarYEsperar(tester, 'a');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();
    await cobrarConfirmando(tester, 1500);

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
    await cobrarConfirmando(tester, 1500);

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
    await cobrarConfirmando(tester, 1500);

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

  testWidgets('"Nuevo Cliente" desde el selector lo crea y lo deja elegido', (tester) async {
    await pumpPos(tester);
    fakeCustomer.clienteIdARetornar = 'cliente-recien-creado';

    await tester.tap(find.byKey(const Key('posCliente')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.byKey(const Key('selectorClienteNuevo')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoClientePosRut')), '12345678-5');
    await tester.enterText(find.byKey(const Key('nuevoClientePosNombre')), 'María López');
    await tester.tap(find.byKey(const Key('nuevoClientePosGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.crearLlamado, isTrue);
    expect(fakeCustomer.ultimoNombreCreado, 'María López');
    expect(fakeCustomer.ultimoRutCreado, '12345678-5');
    expect(find.text('María López'), findsOneWidget);
  });

  testWidgets('"Nuevo Cliente" con RUT inválido muestra error y no llama al repositorio', (tester) async {
    await pumpPos(tester);

    await tester.tap(find.byKey(const Key('posCliente')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.byKey(const Key('selectorClienteNuevo')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoClientePosRut')), '12345678-9');
    await tester.enterText(find.byKey(const Key('nuevoClientePosNombre')), 'María López');
    await tester.tap(find.byKey(const Key('nuevoClientePosGuardar')));
    await tester.pumpAndSettle();

    expect(find.textContaining('RUT no es válido'), findsOneWidget);
    expect(fakeCustomer.crearLlamado, isFalse);
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

  testWidgets('Un producto con oferta vigente muestra el badge y el precio de oferta en la tarjeta', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoOferta];

    await buscarYEsperar(tester, 'televisor');

    expect(find.text('Oferta'), findsOneWidget);
    expect(find.text(r'$399.990'), findsOneWidget);
  });

  testWidgets('Agregar un producto con oferta vigente cobra el precio de oferta y muestra "Oferta aplicada" en el carrito', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoOferta];

    await buscarYEsperar(tester, 'televisor');

    await tester.tap(find.byKey(const Key('posResultado_variante-oferta')));
    await tester.pump();

    expect(textoDe(tester, const Key('posTotal')), r'$399.990');
    expect(find.text('Oferta aplicada'), findsOneWidget);
    expect(find.text(r'$500.000'), findsWidgets);
    expect(find.text(r'x $399.990'), findsOneWidget);
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

  Future<void> abrirMenuCotizacion(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('posCotizacion')));
    await tester.pumpAndSettle();
  }

  testWidgets('El menú de Cotización deshabilita "Guardar" con el carrito vacío y lo habilita con productos',
      (tester) async {
    await pumpPos(tester);

    await abrirMenuCotizacion(tester);
    expect(tester.widget<PopupMenuItem>(find.byKey(const Key('cotizacionGuardarItem'))).enabled, isFalse);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    await abrirMenuCotizacion(tester);
    expect(tester.widget<PopupMenuItem>(find.byKey(const Key('cotizacionGuardarItem'))).enabled, isTrue);
  });

  testWidgets('Rescatar cotización reemplaza el carrito con la Cotización elegida', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-1',
        numeroCotizacion: 'COT-20260801-001',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 3000,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-1',
      numeroCotizacion: 'COT-20260801-001',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 3000,
      total: 3000,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-coca',
          nombreProducto: 'Coca Cola 1.5L',
          sku: 'COCA-15',
          cantidad: 2,
          precioUnitario: 1500,
          subtotal: 3000,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();

    expect(find.text('COT-20260801-001 · Juan Pérez'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget);
    expect(textoDe(tester, const Key('posTotal')), r'$3.000');
    expect(find.text('Cotización rescatada: COT-20260801-001'), findsOneWidget);
  });

  testWidgets('El diálogo de rescatar filtra por número de cotización', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-1',
        numeroCotizacion: 'COT-20260801-001',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 3000,
      ),
      CotizacionResumen(
        ventaId: 'venta-cot-2',
        numeroCotizacion: 'COT-20260802-005',
        fechaVenta: DateTime(2026, 8, 2),
        clienteId: 'cliente-maria',
        clienteNombre: 'María González',
        cantidadLineas: 1,
        total: 5000,
      ),
    ];

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();

    expect(find.text('COT-20260801-001 · Juan Pérez'), findsOneWidget);
    expect(find.text('COT-20260802-005 · María González'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('cotizacionBuscarNumero')), '005');
    await tester.pumpAndSettle();

    expect(find.text('COT-20260801-001 · Juan Pérez'), findsNothing);
    expect(find.text('COT-20260802-005 · María González'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('cotizacionBuscarNumero')), 'no-existe');
    await tester.pumpAndSettle();

    expect(find.text('Ninguna cotización coincide con la búsqueda.'), findsOneWidget);
  });

  testWidgets('El diálogo de rescatar muestra como máximo 10 cotizaciones, con o sin búsqueda', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = List.generate(
      15,
      (i) => CotizacionResumen(
        ventaId: 'venta-cot-$i',
        numeroCotizacion: 'COT-20260806-${(i + 1).toString().padLeft(3, '0')}',
        fechaVenta: DateTime(2026, 8, 6),
        clienteId: 'cliente-generico',
        clienteNombre: 'Cliente Genérico',
        cantidadLineas: 1,
        total: 1000,
      ),
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();

    // El ListView es perezoso (solo construye lo visible), así que se
    // desplaza hasta el final para confirmar que la última permitida
    // (010, décima más reciente) existe, pero la 011 y la 015 no — si el
    // tope no funcionara, seguirían apareciendo al hacer scroll.
    final lista = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.textContaining('COT-20260806-010'), 300, scrollable: lista);
    expect(find.textContaining('COT-20260806-010'), findsOneWidget);
    expect(find.textContaining('COT-20260806-011'), findsNothing);
    expect(find.textContaining('COT-20260806-015'), findsNothing);

    await tester.enterText(find.byKey(const Key('cotizacionBuscarNumero')), 'COT-20260806');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('COT-20260806-010'), 300, scrollable: lista);

    expect(find.textContaining('COT-20260806-010'), findsOneWidget);
    expect(find.textContaining('COT-20260806-011'), findsNothing);
  });

  testWidgets('Rescatar una cotización con descuento por volumen ya aplicado muestra la etiqueta en el carrito', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-2',
        numeroCotizacion: 'COT-20260801-002',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 19000,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-2',
      numeroCotizacion: 'COT-20260801-002',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 19000,
      total: 19000,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-tornillo',
          nombreProducto: 'Tornillo Autoperforante',
          sku: 'TORN-001',
          cantidad: 20,
          precioUnitario: 1000,
          subtotal: 19000,
          porcentajeDescuentoAplicado: 5,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-2')));
    await tester.pumpAndSettle();

    expect(find.text('5% dto. por volumen aplicado'), findsOneWidget);
  });

  testWidgets('Rescatar una cotización con oferta ya aplicada muestra "Oferta aplicada" en el carrito', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-oferta',
        numeroCotizacion: 'COT-20260807-002',
        fechaVenta: DateTime(2026, 8, 7),
        clienteId: 'cliente-generico',
        clienteNombre: 'Cliente Genérico',
        cantidadLineas: 1,
        total: 399990,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-oferta',
      numeroCotizacion: 'COT-20260807-002',
      clienteId: 'cliente-generico',
      clienteNombre: 'Cliente Genérico',
      clienteRut: '66666666-6',
      subtotalLineas: 399990,
      total: 399990,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-oferta',
          nombreProducto: 'TV Test Oferta E2E',
          sku: 'TV-55-4K',
          cantidad: 1,
          precioUnitario: 399990,
          subtotal: 399990,
          precioOferta: 399990,
          precioVenta: 500000,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-oferta')));
    await tester.pumpAndSettle();

    expect(find.text('Oferta aplicada'), findsOneWidget);
    expect(find.text(r'$500.000'), findsOneWidget);
  });

  testWidgets('Rescatar una cotización con promoción por grupo muestra el precio unitario real, no el promedio', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-3',
        numeroCotizacion: 'COT-20260801-003',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 137970,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-3',
      numeroCotizacion: 'COT-20260801-003',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 183960,
      total: 137970,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-neumatico',
          nombreProducto: 'Neumático 175/65 R14',
          sku: 'NEUM-001',
          cantidad: 4,
          precioUnitario: 45990,
          subtotal: 137970,
          montoDescuentoPromocion: 45990,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-3')));
    await tester.pumpAndSettle();

    // Antes de este fix se mostraba "x $34.493" (subtotal/cantidad, el
    // promedio ya rebajado) en vez del precio real guardado en la Cotización.
    expect(find.textContaining(r'x $45.990'), findsOneWidget);
    expect(find.text('Promoción aplicada (-\$45.990)'), findsOneWidget);
    expect(textoDe(tester, const Key('posTotal')), r'$137.970');
  });

  testWidgets('Rescatar una cotización de un producto por Kilogramo muestra la cantidad con su unidad', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-4',
        numeroCotizacion: 'COT-20260806-004',
        fechaVenta: DateTime(2026, 8, 6),
        clienteId: 'cliente-generico',
        clienteNombre: 'Cliente Genérico',
        cantidadLineas: 1,
        total: 3024,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-4',
      numeroCotizacion: 'COT-20260806-004',
      clienteId: 'cliente-generico',
      clienteNombre: 'Cliente Genérico',
      clienteRut: null,
      subtotalLineas: 3024,
      total: 3024,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-pan-hallulla',
          nombreProducto: 'Pan Hallulla',
          sku: 'PAN-HALL',
          cantidad: 1.6,
          precioUnitario: 1890,
          subtotal: 3024,
          unidadMedida: UnidadMedida.kilogramo,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-4')));
    await tester.pumpAndSettle();

    // Antes de este fix la UnidadMedida no viajaba desde el backend y
    // quedaba fija en Unidad, así que un Producto por Kilogramo rescatado
    // mostraba "1.6" en vez de "1.6 kg".
    expect(find.text('1.6 kg'), findsOneWidget);
  });

  testWidgets('Rescatar una cotización con el preset de la promoción disponible muestra "4x3 aplicado", no el texto genérico',
      (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-5',
        numeroCotizacion: 'COT-20260806-005',
        fechaVenta: DateTime(2026, 8, 6),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 137970,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-5',
      numeroCotizacion: 'COT-20260806-005',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 183960,
      total: 137970,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-neumatico',
          nombreProducto: 'Neumático 175/65 R14',
          sku: 'NEUM-001',
          cantidad: 4,
          precioUnitario: 45990,
          subtotal: 137970,
          montoDescuentoPromocion: 45990,
          cantidadPorGrupoPromocion: 4,
          porcentajeDescuentoUnidadPromocion: 100,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-5')));
    await tester.pumpAndSettle();

    // Antes de este fix se mostraba "Promoción aplicada (-$45.990)" (genérico)
    // en vez de la misma etiqueta que se ve al agregar la línea en vivo.
    expect(find.text('4x3 aplicado'), findsOneWidget);
    expect(find.textContaining('Promoción aplicada'), findsNothing);
  });

  testWidgets('Rescatar una cotización con un descuento ya Autorizado no muestra el aviso de "recién autorizado"', (tester) async {
    await pumpPos(tester);
    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-6',
        numeroCotizacion: 'COT-20260806-006',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 1350,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-6',
      numeroCotizacion: 'COT-20260806-006',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 1500,
      total: 1350,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.autorizado,
      descuentoGeneralPorcentaje: 10,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-coca',
          nombreProducto: 'Coca Cola 1.5L',
          sku: 'COCA-15',
          cantidad: 1,
          precioUnitario: 1500,
          subtotal: 1500,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-6')));
    await tester.pumpAndSettle();

    // El descuento ya venía Autorizado desde antes (hecho histórico de la
    // Cotización) — antes de este fix se mostraba el mismo SnackBar que
    // cuando un Supervisor recién autoriza uno en vivo, dando la impresión
    // de que acababa de pasar (bug real reportado por el usuario).
    expect(find.byKey(const Key('posDescuentoAplicado')), findsOneWidget);
    expect(find.text('Descuento autorizado — ya puedes cobrar.'), findsNothing);
  });

  testWidgets('Rescatar con el carrito no vacío pide confirmar antes de reemplazarlo', (tester) async {
    await pumpPos(tester);
    fakeCatalog.resultadosARetornar = [productoCocaCola];
    await buscarYEsperar(tester, 'coca');
    await tester.tap(find.byKey(const Key('posResultado_variante-coca')));
    await tester.pump();

    fakeSales.cotizacionesARetornar = [
      CotizacionResumen(
        ventaId: 'venta-cot-1',
        fechaVenta: DateTime(2026, 8, 1),
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        cantidadLineas: 1,
        total: 800,
      ),
    ];
    fakeSales.cotizacionDetalleARetornar = const CotizacionDetalle(
      ventaId: 'venta-cot-1',
      clienteId: 'cliente-juan',
      clienteNombre: 'Juan Pérez',
      clienteRut: null,
      subtotalLineas: 800,
      total: 800,
      estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
      descuentoGeneralPorcentaje: null,
      descuentoGeneralMonto: null,
      lineas: [
        LineaCotizacionDetalle(
          lineaVentaId: 'linea-fake-1',
          varianteProductoId: 'variante-pan',
          nombreProducto: 'Pan Marraqueta',
          sku: 'PAN-MARR',
          cantidad: 1,
          precioUnitario: 800,
          subtotal: 800,
        ),
      ],
    );

    await abrirMenuCotizacion(tester);
    await tester.tap(find.byKey(const Key('cotizacionRescatarItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cotizacionRescatable_venta-cot-1')));
    await tester.pumpAndSettle();

    expect(find.text('¿Reemplazar el carrito actual?'), findsOneWidget);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsOneWidget, reason: 'todavía no se reemplazó');

    await tester.tap(find.byKey(const Key('confirmarRescatarConfirmar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posCarrito_variante-pan')), findsOneWidget);
    expect(find.byKey(const Key('posCarrito_variante-coca')), findsNothing);
  });

  testWidgets('Sin Sesión de Caja Abierta, ofrece "Abrir Caja" y al confirmar llama al repositorio', (tester) async {
    await pumpPos(tester, sesionCajaAbierta: null);

    expect(find.byKey(const Key('posAbrirCaja')), findsOneWidget);

    await tester.tap(find.byKey(const Key('posAbrirCaja')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('abrirCajaMontoInicial')), '20000');
    await tester.tap(find.byKey(const Key('abrirCajaConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeCash.ultimoCajaIdAbierto, cajaUnica.cajaId);
    expect(fakeCash.ultimoMontoInicial, 20000);
    expect(find.byKey(const Key('posMenuCaja')), findsOneWidget, reason: 'tras abrir, aparece el menú de Caja');
  });

  testWidgets('Sin Sesión de Caja Abierta, el cuerpo del POS queda bloqueado (sin buscador ni carrito)', (tester) async {
    await pumpPos(tester, sesionCajaAbierta: null);

    expect(find.byKey(const Key('posBusqueda')), findsNothing);
    expect(find.byKey(const Key('posCajaCerradaAbrir')), findsOneWidget);
    expect(find.textContaining('está cerrada'), findsOneWidget);
  });

  testWidgets('El botón "Abrir Caja" del cuerpo bloqueado también abre el diálogo y llama al repositorio', (tester) async {
    await pumpPos(tester, sesionCajaAbierta: null);

    await tester.tap(find.byKey(const Key('posCajaCerradaAbrir')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('abrirCajaMontoInicial')), '15000');
    await tester.tap(find.byKey(const Key('abrirCajaConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeCash.ultimoCajaIdAbierto, cajaUnica.cajaId);
    expect(fakeCash.ultimoMontoInicial, 15000);
    expect(find.byKey(const Key('posBusqueda')), findsOneWidget, reason: 'tras abrir, el POS se desbloquea');
  });

  testWidgets('Abrir Caja acepta un monto inicial de cero', (tester) async {
    await pumpPos(tester, sesionCajaAbierta: null);

    await tester.tap(find.byKey(const Key('posAbrirCaja')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('abrirCajaMontoInicial')), '0');
    await tester.tap(find.byKey(const Key('abrirCajaConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeCash.ultimoMontoInicial, 0);
    expect(find.byKey(const Key('posBusqueda')), findsOneWidget);
  });

  testWidgets('Cancelar en el diálogo de Abrir Caja no registra nada y el POS sigue bloqueado', (tester) async {
    await pumpPos(tester, sesionCajaAbierta: null);

    await tester.tap(find.byKey(const Key('posAbrirCaja')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('abrirCajaCancelar')));
    await tester.pumpAndSettle();

    expect(fakeCash.ultimoCajaIdAbierto, isNull);
    expect(find.byKey(const Key('posCajaCerradaAbrir')), findsOneWidget);
    expect(find.byKey(const Key('posBusqueda')), findsNothing);
  });

  testWidgets('Con Sesión Abierta, "Retirar efectivo" solicita el retiro al repositorio', (tester) async {
    await pumpPos(tester);

    await tester.tap(find.byKey(const Key('posMenuCaja')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirar efectivo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('retirarEfectivoMonto')), '20000');
    await tester.enterText(find.byKey(const Key('retirarEfectivoMotivo')), 'Mucho efectivo acumulado');
    await tester.tap(find.byKey(const Key('retirarEfectivoConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeCash.ultimoSesionIdRetiroSolicitado, 'sesion-1');
    expect(fakeCash.ultimoMontoRetiroSolicitado, 20000);
    expect(fakeCash.ultimoMotivoRetiroSolicitado, 'Mucho efectivo acumulado');
  });

  testWidgets('Con Sesión Abierta, "Ver Arqueo" muestra el resumen de la Caja sin cerrarla', (tester) async {
    await pumpPos(tester);
    fakeCash.resumenCierreARetornar = const ResumenCierreCaja(
      sesionCajaId: 'sesion-1',
      cajaId: 'caja-1',
      montoInicial: 20000,
      totalVentasEfectivo: 15000,
      totalVentasTarjetaDebito: 0,
      totalVentasTarjetaCredito: 0,
      totalVentasCredito: 0,
      totalRetiros: 5000,
      montoEsperado: 30000,
      montoContado: null,
      diferencia: null,
      cerrada: false,
      movimientos: [],
    );

    await tester.tap(find.byKey(const Key('posMenuCaja')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver Arqueo'));
    await tester.pumpAndSettle();

    expect(find.text('Arqueo de Caja'), findsOneWidget);
    expect(find.text('Sesión Abierta'), findsOneWidget);
    expect(find.text('Monto esperado'), findsOneWidget);
    expect(find.text('Cerrar Caja'), findsNothing);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Arqueo de Caja'), findsNothing);
  });

  testWidgets(
      '"Registrar devolución por nota de crédito" lista las Notas Disponibles y, al confirmar, las reembolsa en efectivo',
      (tester) async {
    await pumpPos(tester);
    fakeReturns.notasDisponiblesARetornar = [
      NotaCreditoDisponibleResumen(
        id: 'nota-1',
        folio: 'NC-20260813-001',
        clienteId: 'cliente-1',
        clienteNombre: 'Juan Pérez',
        montoTotal: 5000,
        fechaEmision: DateTime(2026, 8, 11, 12),
        motivo: 'Producto defectuoso',
      ),
    ];

    await tester.tap(find.byKey(const Key('posMenuCaja')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar devolución por nota de crédito'));
    await tester.pumpAndSettle();

    expect(find.text('Notas de crédito a devolver en efectivo'), findsOneWidget);
    expect(find.byKey(const Key('devolucionBuscarNotaCredito')), findsOneWidget);
    expect(find.byKey(const Key('devolucionNotaCreditoDisponible_nota-1')), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);

    await tester.tap(find.byKey(const Key('devolucionNotaCreditoDisponible_nota-1')));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar reembolso'), findsOneWidget);

    await tester.tap(find.byKey(const Key('devolucionConfirmarReembolso')));
    await tester.pumpAndSettle();

    expect(fakeReturns.ultimaNotaCreditoIdReembolsada, 'nota-1');
    expect(fakeReturns.ultimaSesionCajaIdDeReembolso, 'sesion-1');
    expect(find.textContaining('reembolsados en efectivo a Juan Pérez'), findsOneWidget);
  });
}
