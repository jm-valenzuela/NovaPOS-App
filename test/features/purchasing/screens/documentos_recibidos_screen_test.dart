import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/purchasing/domain/models/documento_recibido_global.dart';
import 'package:novapos_app/features/purchasing/domain/models/orden_compra.dart';
import 'package:novapos_app/features/purchasing/domain/models/proveedor.dart';
import 'package:novapos_app/features/purchasing/domain/models/purchasing_enums.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/documentos_recibidos_screen.dart';

import '../fakes/purchasing_fakes.dart';

void main() {
  late FakePurchasingRepository fakePurchasing;

  final facturaInterna = DocumentoRecibidoGlobal(
    id: 'documento-1',
    proveedorId: 'proveedor-1',
    proveedorNombre: 'Proveedor Uno',
    proveedorRut: '76.111.111-1',
    ordenCompraId: null,
    tipoDocumento: TipoDocumentoRecibido.factura,
    folio: 111,
    rutEmisor: '76.111.111-1',
    montoTotal: 15000,
    formaPago: FormaPago.contado,
    fechaEmision: DateTime(2026, 8, 12),
    categoria: CategoriaDocumentoRecibido.insumo,
    rutaArchivoRespaldo: '/archivos/documentos-recibidos/e/d/f.pdf',
  );

  final documentoDeOrden = DocumentoRecibidoGlobal(
    id: 'documento-2',
    proveedorId: 'proveedor-2',
    proveedorNombre: 'Proveedor Dos',
    proveedorRut: '76.222.222-2',
    ordenCompraId: 'orden-1',
    tipoDocumento: TipoDocumentoRecibido.factura,
    folio: 222,
    rutEmisor: '76.222.222-2',
    montoTotal: 90000,
    formaPago: FormaPago.credito,
    fechaEmision: DateTime(2026, 8, 12),
    categoria: null,
    rutaArchivoRespaldo: null,
  );

  Future<void> pumpScreen(WidgetTester tester, {List<DocumentoRecibidoGlobal>? documentos}) async {
    fakePurchasing = FakePurchasingRepository()..documentosARetornar = documentos ?? [facturaInterna, documentoDeOrden];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Sin Documentos Recibidos muestra el estado vacío', (tester) async {
    await pumpScreen(tester, documentos: []);

    expect(find.text('Sin Documentos Recibidos'), findsOneWidget);
  });

  testWidgets('Un documento sin Orden de Compra muestra el chip "Factura Interna" con su Categoría', (tester) async {
    await pumpScreen(tester);

    final chipFinder = find.descendant(
      of: find.byKey(const Key('documentoRecibido_documento-1')),
      matching: find.byKey(const Key('chipFacturaInterna')),
    );
    expect(chipFinder, findsOneWidget);
    expect(find.text('Factura Interna · Insumo'), findsOneWidget);
  });

  testWidgets('Un documento ligado a una Orden de Compra muestra el chip "Mercadería"', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Mercadería'), findsOneWidget);
  });

  testWidgets('Muestra el Proveedor de cada documento', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Proveedor Uno'), findsOneWidget);
    expect(find.textContaining('Proveedor Dos'), findsOneWidget);
  });

  testWidgets('Solo el documento con respaldo muestra el botón para verlo', (tester) async {
    await pumpScreen(tester);

    final botonEnConRespaldo = find.descendant(
      of: find.byKey(const Key('documentoRecibido_documento-1')),
      matching: find.byKey(const Key('documentoRecibidoVerRespaldo')),
    );
    final botonEnSinRespaldo = find.descendant(
      of: find.byKey(const Key('documentoRecibido_documento-2')),
      matching: find.byKey(const Key('documentoRecibidoVerRespaldo')),
    );

    expect(botonEnConRespaldo, findsOneWidget);
    expect(botonEnSinRespaldo, findsNothing);
  });

  Future<void> abrirDialogoDesdeElFab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.byKey(const Key('nuevoDocumentoRecibidoBoton')));
    await tester.pumpAndSettle();
  }

  testWidgets('El botón "+" abre el diálogo titulado "Registrar Documento Recibido"', (tester) async {
    await pumpScreen(tester, documentos: []);
    await abrirDialogoDesdeElFab(tester);

    expect(find.text('Registrar Documento Recibido'), findsOneWidget);
  });

  testWidgets('Guardar sin elegir Proveedor muestra el error correspondiente', (tester) async {
    await pumpScreen(tester, documentos: []);
    await abrirDialogoDesdeElFab(tester);

    await tester.enterText(find.byKey(const Key('documentoFolio')), '900');
    await tester.enterText(find.byKey(const Key('documentoRutEmisor')), '76192083-9');
    await tester.enterText(find.byKey(const Key('documentoMonto')), '10000');
    await tester.tap(find.byKey(const Key('documentoGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Elige el Proveedor.'), findsOneWidget);
    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, isNull);
  });

  testWidgets('Elegir un Proveedor precompleta el RUT emisor y muestra el selector de Orden de Compra', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..documentosARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('documentoProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    expect(find.text('Proveedor Existente'), findsOneWidget);
    final campoRutEmisor = tester.widget<TextField>(find.byKey(const Key('documentoRutEmisor')));
    expect(campoRutEmisor.controller!.text, '76192083-9');
    expect(find.byKey(const Key('documentoOrdenCompra')), findsOneWidget);
  });

  testWidgets('Sin elegir Orden de Compra, exige elegir una Categoría antes de guardar', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..documentosARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('documentoProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('documentoFolio')), '500');
    await tester.enterText(find.byKey(const Key('documentoMonto')), '10000');
    await tester.tap(find.byKey(const Key('documentoGuardar')));
    await tester.pumpAndSettle();

    expect(find.textContaining('elige una Categoría'), findsOneWidget);
    expect(fakePurchasing.ultimoOrdenCompraIdDocumento, isNull);
    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, isNull);
  });

  testWidgets('Sin Orden de Compra, elegir una Categoría permite guardar como Factura Interna', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..documentosARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('documentoProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('documentoFolio')), '500');
    await tester.enterText(find.byKey(const Key('documentoMonto')), '10000');
    await tester.tap(find.byKey(const Key('documentoCategoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicio').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('documentoGuardar')));
    await tester.pumpAndSettle();

    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, 'proveedor-9');
    expect(fakePurchasing.ultimaCategoriaDocumento, CategoriaDocumentoRecibido.servicio);
    expect(fakePurchasing.ultimoOrdenCompraIdDocumento, isNull);
  });

  testWidgets('Elegir una Orden de Compra oculta el selector de Categoría y no la envía', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..documentosARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ]
      ..ordenesARetornar = [
        OrdenCompraResumenListado(
          id: 'orden-recibida-1',
          proveedorId: 'proveedor-9',
          proveedorNombre: 'Proveedor Existente',
          estado: EstadoOrdenCompra.recibida,
          total: 50000,
          fechaCreacionOrden: DateTime(2026, 8, 1),
          fechaEnvio: DateTime(2026, 8, 2),
          fechaRecepcion: DateTime(2026, 8, 5),
        ),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('documentoProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('documentoFolio')), '500');
    await tester.enterText(find.byKey(const Key('documentoMonto')), '10000');

    await tester.tap(find.byKey(const Key('documentoOrdenCompra')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('orden-re').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('documentoCategoria')), findsNothing);

    await tester.tap(find.byKey(const Key('documentoGuardar')));
    await tester.pumpAndSettle();

    expect(fakePurchasing.ultimoOrdenCompraIdDocumento, 'orden-recibida-1');
    expect(fakePurchasing.ultimaCategoriaDocumento, isNull);
    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, 'proveedor-9');
  });

  testWidgets('Crear un Proveedor rápido desde el selector lo deja elegido en el diálogo', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..documentosARetornar = []
      ..proveedoresARetornar = const []
      ..proveedorIdARetornar = 'proveedor-rapido-1';

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: DocumentosRecibidosScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('documentoProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorNuevo')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoProveedorRapidoRut')), '76192083-9');
    await tester.enterText(find.byKey(const Key('nuevoProveedorRapidoNombre')), 'Proveedor Rápido');
    await tester.tap(find.byKey(const Key('nuevoProveedorRapidoGuardar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selectorProveedorBusqueda')), findsNothing);
    expect(find.text('Proveedor Rápido'), findsOneWidget);
  });
}
