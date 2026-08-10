import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/payables/domain/models/cuenta_por_pagar_detalle.dart';
import 'package:novapos_app/features/payables/domain/models/proveedor_por_pagar.dart';
import 'package:novapos_app/features/payables/presentation/providers/payables_providers.dart';
import 'package:novapos_app/features/payables/presentation/screens/cuentas_por_pagar_screen.dart';
import 'package:novapos_app/features/payables/presentation/screens/detalle_cuenta_proveedor_screen.dart';

import '../fakes/payables_fakes.dart';

const _proveedorAtrasado = ProveedorPorPagar(
  proveedorId: 'proveedor-1',
  nombre: 'Proveedor Atrasado',
  rut: '11111111-1',
  saldoTotal: 30000,
  saldoVencido: 30000,
  saldoPorVencer: 0,
  diasAtraso: 45,
);

const _proveedorPorVencer = ProveedorPorPagar(
  proveedorId: 'proveedor-2',
  nombre: 'Proveedor Al Corriente',
  rut: '22222222-2',
  saldoTotal: 5000,
  saldoVencido: 0,
  saldoPorVencer: 5000,
  diasAtraso: 0,
);

void main() {
  late FakePayablesRepository fakePayables;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakePayables = FakePayablesRepository()..cuentasPorPagarARetornar = [_proveedorAtrasado, _proveedorPorVencer];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CuentasPorPagarScreen()),
      GoRoute(
        path: '/compras/cuentas-por-pagar/:id',
        builder: (context, state) => DetalleCuentaProveedorScreen(proveedorId: state.pathParameters['id']!),
      ),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [payablesRepositoryProvider.overrideWithValue(fakePayables)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra los Proveedores con saldo, más atrasado primero (ya viene ordenado del backend)', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Proveedor Atrasado'), findsOneWidget);
    expect(find.text('Proveedor Al Corriente'), findsOneWidget);
    expect(find.textContaining('Vencido'), findsOneWidget);
    expect(find.text('Por vencer'), findsOneWidget);
  });

  testWidgets('Sin Proveedores con saldo, muestra el mensaje vacío', (tester) async {
    fakePayables = FakePayablesRepository()..cuentasPorPagarARetornar = [];
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CuentasPorPagarScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [payablesRepositoryProvider.overrideWithValue(fakePayables)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Sin Proveedores con saldo'), findsOneWidget);
  });

  testWidgets('Tocar un Proveedor navega al detalle de su Cuenta', (tester) async {
    await pumpPantalla(tester);
    fakePayables.detalleARetornar = const CuentaPorPagarDetalle(
      proveedorId: 'proveedor-1',
      nombreProveedor: 'Proveedor Atrasado',
      rutProveedor: '11111111-1',
      saldoActual: 30000,
      movimientos: [],
    );

    await tester.tap(find.byKey(const Key('cuentaPorPagarProveedor_proveedor-1')));
    await tester.pumpAndSettle();

    expect(fakePayables.ultimoProveedorIdConsultado, 'proveedor-1');
  });
}
