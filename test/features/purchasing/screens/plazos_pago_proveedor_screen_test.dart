import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/purchasing/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/plazos_pago_proveedor_screen.dart';

import '../fakes/purchasing_fakes.dart';

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
  late FakePurchasingRepository fakePurchasing;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakePurchasing = FakePurchasingRepository()..plazosPagoARetornar = [_plazo30, _plazo306090Inactivo];

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: PlazosPagoProveedorScreen()),
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
    fakePurchasing = FakePurchasingRepository()..plazosPagoARetornar = [];
    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: const MaterialApp(home: PlazosPagoProveedorScreen()),
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

    expect(fakePurchasing.ultimoPlazoPagoIdDesactivado, 'plazo-30');
  });

  testWidgets('Activar un Plazo inactivo llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('plazoPagoToggle_plazo-306090')));
    await tester.pump();
    await tester.pump();

    expect(fakePurchasing.ultimoPlazoPagoIdActivado, 'plazo-306090');
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

    expect(fakePurchasing.ultimoNombrePlazoPagoCreado, '30-60 días');
    expect(fakePurchasing.ultimasDiasCuotasCreadas, [30, 60]);
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
    expect(fakePurchasing.ultimoNombrePlazoPagoCreado, isNull);
  });
}
