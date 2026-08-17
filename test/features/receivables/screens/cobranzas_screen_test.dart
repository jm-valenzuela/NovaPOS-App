import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/customers/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/receivables/domain/models/cliente_cobranza.dart';
import 'package:novapos_app/features/receivables/domain/models/cuenta_por_cobrar_detalle.dart';
import 'package:novapos_app/features/receivables/presentation/providers/receivables_providers.dart';
import 'package:novapos_app/features/receivables/presentation/screens/cobranzas_screen.dart';
import 'package:novapos_app/features/receivables/presentation/screens/detalle_cuenta_cliente_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';
import '../fakes/receivables_fakes.dart';

const _plazo30Dias = PlazoPago(id: 'plazo-30', nombre: '30 días', activo: true, cuotas: []);

const _clienteAtrasado = ClienteCobranza(
  clienteId: 'cliente-1',
  nombre: 'Cliente Atrasado',
  rut: '11111111-1',
  cupoCredito: 50000,
  plazoPagoId: null,
  saldoTotal: 30000,
  saldoVencido: 30000,
  saldoPorVencer: 0,
  diasAtraso: 45,
);

const _clientePorVencer = ClienteCobranza(
  clienteId: 'cliente-2',
  nombre: 'Cliente Al Corriente',
  rut: '22222222-2',
  cupoCredito: 100000,
  plazoPagoId: 'plazo-30',
  saldoTotal: 5000,
  saldoVencido: 0,
  saldoPorVencer: 5000,
  diasAtraso: 0,
);

const _clienteSinDeuda = ClienteCobranza(
  clienteId: 'cliente-3',
  nombre: 'Cliente Recién Aprobado',
  rut: '33333333-3',
  cupoCredito: 200000,
  plazoPagoId: null,
  saldoTotal: 0,
  saldoVencido: 0,
  saldoPorVencer: 0,
  diasAtraso: 0,
);

void main() {
  late FakeReceivablesRepository fakeReceivables;

  Future<void> pumpPantalla(WidgetTester tester, {required List<ClienteCobranza> clientes}) async {
    fakeReceivables = FakeReceivablesRepository()..cobranzaARetornar = clientes;
    final fakeCustomers = FakeCustomerRepository()..plazosPagoARetornar = [_plazo30Dias];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CobranzasScreen()),
      GoRoute(
        path: '/clientes/cobranzas/:id',
        builder: (context, state) => DetalleCuentaClienteScreen(clienteId: state.pathParameters['id']!),
      ),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        receivablesRepositoryProvider.overrideWithValue(fakeReceivables),
        customerRepositoryProvider.overrideWithValue(fakeCustomers),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra todos los Clientes con Cupo de Crédito, más atrasado primero', (tester) async {
    await pumpPantalla(tester, clientes: [_clienteAtrasado, _clientePorVencer]);

    expect(find.text('Cliente Atrasado'), findsOneWidget);
    expect(find.text('Cliente Al Corriente'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Vencido (45d)'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Por vencer'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
  });

  testWidgets('Un Cliente con Cupo pero sin deuda vigente igual aparece, marcado Al día', (tester) async {
    await pumpPantalla(tester, clientes: [_clienteSinDeuda]);

    expect(find.text('Cliente Recién Aprobado'), findsOneWidget);
    expect(find.text('Al día'), findsOneWidget);
  });

  testWidgets('Sin Clientes con Cupo de Crédito, muestra el mensaje vacío', (tester) async {
    fakeReceivables = FakeReceivablesRepository()..cobranzaARetornar = [];
    final fakeCustomers = FakeCustomerRepository();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const CobranzasScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        receivablesRepositoryProvider.overrideWithValue(fakeReceivables),
        customerRepositoryProvider.overrideWithValue(fakeCustomers),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Sin Clientes con Cupo'), findsOneWidget);
  });

  testWidgets('Tocar un Cliente navega al detalle de su Cuenta', (tester) async {
    await pumpPantalla(tester, clientes: [_clienteAtrasado, _clientePorVencer]);
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
