import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/customers/presentation/screens/clientes_admin_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';

const _clienteJuan = ClienteResumen(
  id: 'cliente-1',
  rut: '12.345.678-5',
  nombre: 'Juan Pérez',
  email: 'juan@correo.cl',
  telefono: null,
  cupoCredito: 100000,
  plazoPagoDias: 30,
);

void main() {
  late FakeCustomerRepository fakeCustomer;

  Future<void> pumpClientes(WidgetTester tester) async {
    fakeCustomer = FakeCustomerRepository()..resultadosARetornar = [_clienteJuan];

    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: ClientesAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de Clientes', (tester) async {
    await pumpClientes(tester);

    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('12.345.678-5'), findsOneWidget);
  });

  testWidgets('Tocar un Cliente abre el formulario de edición con el RUT deshabilitado y los datos precargados', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.text('Juan Pérez'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Cliente'), findsOneWidget);
    final campoRut = tester.widget<TextField>(find.byKey(const Key('clienteRut')));
    expect(campoRut.enabled, isFalse);
    expect(campoRut.controller?.text, '12.345.678-5');
    expect(find.byKey(const Key('clienteCupoCredito')), findsNothing);
  });

  testWidgets('Guardar la edición llama a actualizarCliente', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.text('Juan Pérez'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.ultimoClienteIdActualizado, 'cliente-1');
  });

  testWidgets('Tocar el FAB abre el formulario de alta', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.byKey(const Key('nuevoClienteBoton')));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo Cliente'), findsOneWidget);
    final campoRut = tester.widget<TextField>(find.byKey(const Key('clienteRut')));
    expect(campoRut.enabled, isTrue);
  });

  testWidgets('Alta sin RUT muestra error y no crea el Cliente', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.byKey(const Key('nuevoClienteBoton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clienteNombre')), 'Empresa Nueva SpA');
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pump();

    expect(find.text('El RUT es obligatorio.'), findsOneWidget);
    expect(fakeCustomer.crearLlamado, isFalse);
  });

  testWidgets('Alta con RUT válido crea el Cliente', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.byKey(const Key('nuevoClienteBoton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clienteRut')), '76.543.210-3');
    await tester.enterText(find.byKey(const Key('clienteNombre')), 'Empresa Nueva SpA');
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.crearLlamado, isTrue);
    expect(fakeCustomer.ultimoRutCreado, '76543210-3');
  });
}
