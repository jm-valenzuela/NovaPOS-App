import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/receivables/domain/models/cliente_cobranza.dart';
import 'package:novapos_app/features/receivables/domain/models/cuenta_por_cobrar_detalle.dart';
import 'package:novapos_app/features/receivables/presentation/providers/receivables_providers.dart';
import 'package:novapos_app/features/receivables/presentation/screens/cobranzas_screen.dart';
import 'package:novapos_app/features/receivables/presentation/screens/detalle_cuenta_cliente_screen.dart';

import '../fakes/receivables_fakes.dart';

const _clienteAtrasado = ClienteCobranza(
  clienteId: 'cliente-1',
  nombre: 'Cliente Atrasado',
  rut: '11111111-1',
  saldoTotal: 30000,
  saldoVencido: 30000,
  saldoPorVencer: 0,
  diasAtraso: 45,
);

const _clientePorVencer = ClienteCobranza(
  clienteId: 'cliente-2',
  nombre: 'Cliente Al Corriente',
  rut: '22222222-2',
  saldoTotal: 5000,
  saldoVencido: 0,
  saldoPorVencer: 5000,
  diasAtraso: 0,
);

void main() {
  late FakeReceivablesRepository fakeReceivables;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakeReceivables = FakeReceivablesRepository()..cobranzaARetornar = [_clienteAtrasado, _clientePorVencer];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CobranzasScreen()),
      GoRoute(
        path: '/clientes/cobranzas/:id',
        builder: (context, state) => DetalleCuentaClienteScreen(clienteId: state.pathParameters['id']!),
      ),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [receivablesRepositoryProvider.overrideWithValue(fakeReceivables)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra los Clientes con saldo, más atrasado primero (ya viene ordenado del backend)', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Cliente Atrasado'), findsOneWidget);
    expect(find.text('Cliente Al Corriente'), findsOneWidget);
    expect(find.textContaining('Vencido'), findsOneWidget);
    expect(find.text('Por vencer'), findsOneWidget);
  });

  testWidgets('Sin Clientes con saldo, muestra el mensaje vacío', (tester) async {
    fakeReceivables = FakeReceivablesRepository()..cobranzaARetornar = [];
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CobranzasScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [receivablesRepositoryProvider.overrideWithValue(fakeReceivables)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Sin Clientes con saldo'), findsOneWidget);
  });

  testWidgets('Tocar un Cliente navega al detalle de su Cuenta', (tester) async {
    await pumpPantalla(tester);
    fakeReceivables.detalleARetornar = const CuentaPorCobrarDetalle(
      clienteId: 'cliente-1',
      nombreCliente: 'Cliente Atrasado',
      rutCliente: '11111111-1',
      saldoActual: 30000,
      movimientos: [],
    );

    await tester.tap(find.byKey(const Key('cobranzaCliente_cliente-1')));
    await tester.pumpAndSettle();

    expect(fakeReceivables.ultimoClienteIdConsultado, 'cliente-1');
  });
}
