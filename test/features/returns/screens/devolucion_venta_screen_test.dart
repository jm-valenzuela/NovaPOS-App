import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/returns/domain/models/venta_confirmada_resumen.dart';
import 'package:novapos_app/features/returns/presentation/providers/returns_providers.dart';
import 'package:novapos_app/features/returns/presentation/screens/devolucion_venta_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show tenancyRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';
import '../fakes/returns_fakes.dart';

void main() {
  late FakeTenancyRepository fakeTenancy;
  late FakeReturnsRepository fakeReturns;

  final ventaJuan = VentaConfirmadaResumen(
    ventaId: 'venta-1',
    fechaConfirmacion: DateTime(2026, 8, 13, 12),
    clienteId: 'cliente-1',
    clienteNombre: 'Juan Pérez',
    clienteRut: '12345678-5',
    total: 5000,
    cantidadLineas: 1,
  );

  final ventaGenerico = VentaConfirmadaResumen(
    ventaId: 'venta-2',
    fechaConfirmacion: DateTime(2026, 8, 13, 13),
    clienteId: 'cliente-generico',
    clienteNombre: 'Cliente Genérico',
    clienteRut: '66666666-6',
    total: 2000,
    cantidadLineas: 1,
  );

  Future<void> pumpScreen(WidgetTester tester, {List<VentaConfirmadaResumen>? ventas}) async {
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeReturns = FakeReturnsRepository()..ventasARetornar = ventas ?? [ventaJuan, ventaGenerico];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        returnsRepositoryProvider.overrideWithValue(fakeReturns),
      ],
      child: const MaterialApp(home: DevolucionVentaScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Con una sola Sucursal, la elige automáticamente y muestra la lista de Ventas Confirmadas', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('devolucionVentaItem_venta-1')), findsOneWidget);
    expect(find.byKey(const Key('devolucionVentaItem_venta-2')), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Cliente Genérico'), findsOneWidget);
  });

  testWidgets('Buscar filtra por nombre de Cliente', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('devolucionVentaBuscar')), 'juan');
    await tester.pump();

    expect(find.byKey(const Key('devolucionVentaItem_venta-1')), findsOneWidget);
    expect(find.byKey(const Key('devolucionVentaItem_venta-2')), findsNothing);
  });

  testWidgets('Buscar filtra por RUT', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('devolucionVentaBuscar')), '66666666');
    await tester.pump();

    expect(find.byKey(const Key('devolucionVentaItem_venta-1')), findsNothing);
    expect(find.byKey(const Key('devolucionVentaItem_venta-2')), findsOneWidget);
  });

  testWidgets('Sin Ventas Confirmadas, muestra el mensaje vacío', (tester) async {
    await pumpScreen(tester, ventas: []);

    expect(find.textContaining('No hay Ventas Confirmadas'), findsOneWidget);
  });
}
