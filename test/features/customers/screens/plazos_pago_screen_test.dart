import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/customers/presentation/screens/plazos_pago_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';

const _plazo30 = PlazoPago(
  id: 'plazo-30',
  nombre: 'Un mes',
  activo: true,
  cuotas: [CuotaPlazoPago(numeroCuota: 1, diasVencimiento: 30)],
);

const _plazo306090Inactivo = PlazoPago(
  id: 'plazo-306090',
  nombre: '30-60-90 días',
  activo: false,
  cuotas: [
    CuotaPlazoPago(numeroCuota: 1, diasVencimiento: 30),
    CuotaPlazoPago(numeroCuota: 2, diasVencimiento: 60),
    CuotaPlazoPago(numeroCuota: 3, diasVencimiento: 90),
  ],
);

void main() {
  late FakeCustomerRepository fakeCustomer;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakeCustomer = FakeCustomerRepository()..plazosPagoARetornar = [_plazo30, _plazo306090Inactivo];

    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: PlazosPagoScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de Plazos de Pago con sus cuotas y estado', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Un mes'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('30-60-90 días (3 cuotas)'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('Sin Plazos, muestra el mensaje vacío', (tester) async {
    fakeCustomer = FakeCustomerRepository()..plazosPagoARetornar = [];
    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: PlazosPagoScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Sin Plazos de Pago'), findsOneWidget);
  });

  testWidgets('Desactivar un Plazo activo llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('plazoPagoToggle_plazo-30')));
    await tester.pump();
    await tester.pump();

    expect(fakeCustomer.ultimoPlazoPagoIdDesactivado, 'plazo-30');
  });

  testWidgets('Activar un Plazo inactivo llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('plazoPagoToggle_plazo-306090')));
    await tester.pump();
    await tester.pump();

    expect(fakeCustomer.ultimoPlazoPagoIdActivado, 'plazo-306090');
  });

  testWidgets('Crear un Plazo con varias cuotas llama al repositorio con los días ingresados', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('nuevoPlazoPagoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('plazoPagoNombre')), '30-60 días');
    await tester.enterText(find.byKey(const Key('plazoPagoCuota_0')), '30');
    await tester.tap(find.byKey(const Key('plazoPagoAgregarCuota')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('plazoPagoCuota_1')), '60');
    await tester.tap(find.byKey(const Key('plazoPagoGuardar')));
    await tester.pumpAndSettle();

    expect(fakeCustomer.ultimoNombrePlazoPagoCreado, '30-60 días');
    expect(fakeCustomer.ultimasDiasCuotasCreadas, [30, 60]);
  });

  testWidgets('Crear un Plazo con cuotas no crecientes muestra error y no llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('nuevoPlazoPagoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('plazoPagoNombre')), 'Inválido');
    await tester.enterText(find.byKey(const Key('plazoPagoCuota_0')), '30');
    await tester.tap(find.byKey(const Key('plazoPagoAgregarCuota')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('plazoPagoCuota_1')), '20');
    await tester.tap(find.byKey(const Key('plazoPagoGuardar')));
    await tester.pump();

    expect(find.textContaining('estrictamente crecientes'), findsOneWidget);
    expect(fakeCustomer.ultimoNombrePlazoPagoCreado, isNull);
  });
}
