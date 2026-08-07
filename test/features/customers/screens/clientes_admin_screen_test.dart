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

const _clienteSinRut = ClienteResumen(
  id: 'cliente-2',
  rut: null,
  nombre: 'Cliente Sin Rut',
  email: null,
  telefono: null,
  cupoCredito: 0,
  plazoPagoDias: 0,
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

  testWidgets('Alta con datos de Factura los envía junto con el Cliente', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.byKey(const Key('nuevoClienteBoton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clienteRut')), '76.543.210-3');
    await tester.enterText(find.byKey(const Key('clienteNombre')), 'Empresa Nueva SpA');
    await tester.enterText(find.byKey(const Key('clienteGiro')), 'Venta al por menor');
    await tester.enterText(find.byKey(const Key('clienteDireccion')), 'Av. Siempre Viva 123');
    await tester.enterText(find.byKey(const Key('clienteComuna')), 'Providencia');
    await tester.enterText(find.byKey(const Key('clienteCiudad')), 'Santiago');
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.crearLlamado, isTrue);
    expect(fakeCustomer.ultimoGiro, 'Venta al por menor');
    expect(fakeCustomer.ultimaDireccion, 'Av. Siempre Viva 123');
    expect(fakeCustomer.ultimaComuna, 'Providencia');
    expect(fakeCustomer.ultimaCiudad, 'Santiago');
  });

  testWidgets('Alta sin datos de Factura los envía como null (son opcionales)', (tester) async {
    await pumpClientes(tester);

    await tester.tap(find.byKey(const Key('nuevoClienteBoton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clienteRut')), '76.543.210-3');
    await tester.enterText(find.byKey(const Key('clienteNombre')), 'Empresa Nueva SpA');
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.crearLlamado, isTrue);
    expect(fakeCustomer.ultimoGiro, isNull);
    expect(fakeCustomer.ultimaDireccion, isNull);
  });

  testWidgets('Editar un Cliente precarga los datos de Factura ya guardados', (tester) async {
    const clienteConFactura = ClienteResumen(
      id: 'cliente-3',
      rut: '12.345.678-5',
      nombre: 'Factura SpA',
      email: null,
      telefono: null,
      giro: 'Venta al por menor',
      direccion: 'Av. Siempre Viva 123',
      comuna: 'Providencia',
      ciudad: 'Santiago',
    );
    fakeCustomer = FakeCustomerRepository()..resultadosARetornar = [clienteConFactura];
    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: ClientesAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Factura SpA'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byKey(const Key('clienteGiro'))).controller?.text, 'Venta al por menor');
    expect(tester.widget<TextField>(find.byKey(const Key('clienteDireccion'))).controller?.text, 'Av. Siempre Viva 123');
    expect(tester.widget<TextField>(find.byKey(const Key('clienteComuna'))).controller?.text, 'Providencia');
    expect(tester.widget<TextField>(find.byKey(const Key('clienteCiudad'))).controller?.text, 'Santiago');
  });

  testWidgets('Editar un Cliente sin RUT habilita el campo para completarlo', (tester) async {
    fakeCustomer = FakeCustomerRepository()..resultadosARetornar = [_clienteSinRut];
    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: ClientesAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Cliente Sin Rut'));
    await tester.pumpAndSettle();

    final campoRut = tester.widget<TextField>(find.byKey(const Key('clienteRut')));
    expect(campoRut.enabled, isTrue);
    expect(campoRut.controller?.text, isEmpty);
  });

  testWidgets('Completar el RUT de un Cliente sin RUT llama a asignarRutCliente', (tester) async {
    fakeCustomer = FakeCustomerRepository()..resultadosARetornar = [_clienteSinRut];
    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: ClientesAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Cliente Sin Rut'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clienteRut')), '76.543.210-3');
    await tester.tap(find.byKey(const Key('clienteGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.ultimoClienteIdConRutAsignado, 'cliente-2');
    expect(fakeCustomer.ultimoRutAsignado, '76543210-3');
  });
}
