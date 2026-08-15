import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/purchasing/domain/models/factura_interna.dart';
import 'package:novapos_app/features/purchasing/domain/models/proveedor.dart';
import 'package:novapos_app/features/purchasing/domain/models/purchasing_enums.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/facturas_internas_screen.dart';

import '../fakes/purchasing_fakes.dart';

void main() {
  late FakePurchasingRepository fakePurchasing;

  final facturaConRespaldo = FacturaInterna(
    id: 'factura-1',
    proveedorId: 'proveedor-1',
    proveedorNombre: 'Distribuidora Uno',
    proveedorRut: '76192083-9',
    tipoDocumento: TipoDocumentoRecibido.factura,
    folio: 111,
    rutEmisor: '76192083-9',
    montoTotal: 45000,
    formaPago: FormaPago.contado,
    fechaEmision: DateTime(2026, 8, 12),
    categoria: CategoriaDocumentoRecibido.servicio,
    rutaArchivoRespaldo: '/archivos/documentos-recibidos/e/d/f.pdf',
  );

  final facturaSinRespaldo = FacturaInterna(
    id: 'factura-2',
    proveedorId: 'proveedor-2',
    proveedorNombre: 'Insumos Dos',
    proveedorRut: '12345678-5',
    tipoDocumento: TipoDocumentoRecibido.boleta,
    folio: 222,
    rutEmisor: '12345678-5',
    montoTotal: 8000,
    formaPago: FormaPago.contado,
    fechaEmision: DateTime(2026, 8, 11),
    categoria: CategoriaDocumentoRecibido.gasto,
    rutaArchivoRespaldo: null,
  );

  Future<void> pumpScreen(WidgetTester tester, {List<FacturaInterna>? facturas}) async {
    fakePurchasing = FakePurchasingRepository()..facturasInternasARetornar = facturas ?? [facturaConRespaldo, facturaSinRespaldo];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: FacturasInternasScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Sin Facturas Internas muestra el estado vacío', (tester) async {
    await pumpScreen(tester, facturas: []);

    expect(find.text('Sin Facturas Internas registradas'), findsOneWidget);
  });

  testWidgets('Lista muestra Proveedor, tipo/folio y la Categoría', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Distribuidora Uno'), findsOneWidget);
    expect(find.textContaining('Factura N° 111'), findsOneWidget);
    expect(find.text('Servicio'), findsOneWidget);
    expect(find.text('Gasto'), findsOneWidget);
  });

  testWidgets('Solo la Factura con respaldo muestra el ícono de adjunto', (tester) async {
    await pumpScreen(tester);

    final iconoEnFacturaConRespaldo = find.descendant(
      of: find.byKey(const Key('facturaInterna_factura-1')),
      matching: find.byKey(const Key('facturaInternaConRespaldo')),
    );
    final iconoEnFacturaSinRespaldo = find.descendant(
      of: find.byKey(const Key('facturaInterna_factura-2')),
      matching: find.byKey(const Key('facturaInternaConRespaldo')),
    );

    expect(iconoEnFacturaConRespaldo, findsOneWidget);
    expect(iconoEnFacturaSinRespaldo, findsNothing);
  });

  Future<void> abrirDialogoDesdeElFab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.byKey(const Key('nuevaFacturaInternaBoton')));
    await tester.pumpAndSettle();
  }

  testWidgets('El botón "+" abre el diálogo titulado "Registrar Factura Interna"', (tester) async {
    await pumpScreen(tester, facturas: []);
    await abrirDialogoDesdeElFab(tester);

    expect(find.text('Registrar Factura Interna'), findsOneWidget);
  });

  testWidgets('Guardar sin elegir Proveedor muestra el error correspondiente', (tester) async {
    await pumpScreen(tester, facturas: []);
    await abrirDialogoDesdeElFab(tester);

    await tester.enterText(find.byKey(const Key('facturaInternaFolio')), '900');
    await tester.enterText(find.byKey(const Key('facturaInternaRutEmisor')), '76192083-9');
    await tester.enterText(find.byKey(const Key('facturaInternaMonto')), '10000');
    await tester.tap(find.byKey(const Key('facturaInternaGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Elige el Proveedor.'), findsOneWidget);
    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, isNull);
  });

  testWidgets('Elegir un Proveedor existente vía el buscador lo deja seleccionado y precompleta el RUT emisor', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..facturasInternasARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: FacturasInternasScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('facturaInternaProveedor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selectorProveedorBusqueda')), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    expect(find.text('Proveedor Existente'), findsOneWidget);
    final campoRutEmisor = tester.widget<TextField>(find.byKey(const Key('facturaInternaRutEmisor')));
    expect(campoRutEmisor.controller!.text, '76192083-9');
  });

  testWidgets('Crear un Proveedor rápido desde el selector lo deja elegido en el diálogo', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..facturasInternasARetornar = []
      ..proveedoresARetornar = const []
      ..proveedorIdARetornar = 'proveedor-rapido-1';

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: FacturasInternasScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('facturaInternaProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorNuevo')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoProveedorRapidoRut')), '76192083-9');
    await tester.enterText(find.byKey(const Key('nuevoProveedorRapidoNombre')), 'Proveedor Rápido');
    await tester.tap(find.byKey(const Key('nuevoProveedorRapidoGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Elegir Proveedor'), findsNothing);
    expect(find.text('Proveedor Rápido'), findsOneWidget);
  });

  testWidgets('Con Proveedor, folio, RUT, monto y Categoría, Registrar guarda y no envía Orden de Compra', (tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..facturasInternasARetornar = []
      ..proveedoresARetornar = const [
        ProveedorResumen(id: 'proveedor-9', rut: '76192083-9', nombre: 'Proveedor Existente', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: FacturasInternasScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await abrirDialogoDesdeElFab(tester);

    await tester.tap(find.byKey(const Key('facturaInternaProveedor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectorProveedorResultado_proveedor-9')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('facturaInternaFolio')), '900');
    await tester.enterText(find.byKey(const Key('facturaInternaMonto')), '10000');
    await tester.tap(find.byKey(const Key('facturaInternaCategoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insumo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('facturaInternaGuardar')));
    await tester.pumpAndSettle();

    expect(fakePurchasing.ultimoProveedorIdDocumentoRegistrado, 'proveedor-9');
    expect(fakePurchasing.ultimoOrdenCompraIdDocumento, isNull);
    expect(fakePurchasing.ultimaCategoriaDocumento, CategoriaDocumentoRecibido.insumo);
    expect(fakePurchasing.ultimoDocumentoIdConRespaldo, isNull);
  });
}
