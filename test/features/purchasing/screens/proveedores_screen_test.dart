import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/purchasing/domain/models/proveedor.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/proveedores_screen.dart';

import '../fakes/purchasing_fakes.dart';

const _proveedorDistribuidora = ProveedorResumen(
  id: 'proveedor-1',
  rut: '76.123.456-0',
  nombre: 'Distribuidora Central',
  email: 'contacto@dc.cl',
  telefono: '+56221111111',
  plazoPagoDias: 30,
);

void main() {
  late FakePurchasingRepository fakePurchasing;

  Future<void> pumpProveedores(WidgetTester tester) async {
    fakePurchasing = FakePurchasingRepository()..proveedoresARetornar = [_proveedorDistribuidora];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: ProveedoresScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de Proveedores', (tester) async {
    await pumpProveedores(tester);

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.textContaining('76.123.456-0'), findsOneWidget);
  });

  testWidgets('Buscar llama al repositorio con el texto ingresado', (tester) async {
    await pumpProveedores(tester);

    await tester.enterText(find.byKey(const Key('proveedoresBusqueda')), 'Central');
    await tester.pump();

    expect(fakePurchasing.ultimoTextoBuscado, 'Central');
  });

  testWidgets('Tocar el FAB abre el formulario de alta con el RUT habilitado', (tester) async {
    await pumpProveedores(tester);

    await tester.tap(find.byKey(const Key('nuevoProveedorBoton')));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo Proveedor'), findsOneWidget);
    final campoRut = tester.widget<TextField>(find.byKey(const Key('proveedorRut')));
    expect(campoRut.enabled, isTrue);
  });

  testWidgets('Tocar un Proveedor abre el formulario de edición con el RUT deshabilitado y precargado', (tester) async {
    await pumpProveedores(tester);

    await tester.tap(find.text('Distribuidora Central'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Proveedor'), findsOneWidget);
    final campoRut = tester.widget<TextField>(find.byKey(const Key('proveedorRut')));
    expect(campoRut.enabled, isFalse);
    expect(campoRut.controller?.text, '76.123.456-0');
  });

  testWidgets('Guardar la edición llama a actualizarProveedor y recarga la lista', (tester) async {
    await pumpProveedores(tester);

    await tester.tap(find.text('Distribuidora Central'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('proveedorNombre')), 'Distribuidora Central Ltda.');
    await tester.tap(find.byKey(const Key('proveedorGuardar')));
    await tester.pumpAndSettle();

    expect(fakePurchasing.ultimoProveedorIdActualizado, 'proveedor-1');
  });
}
