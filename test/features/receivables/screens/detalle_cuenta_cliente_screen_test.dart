import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/receivables/domain/models/cuenta_por_cobrar_detalle.dart';
import 'package:novapos_app/features/receivables/domain/models/movimiento_cuenta_cliente.dart';
import 'package:novapos_app/features/receivables/presentation/providers/receivables_providers.dart';
import 'package:novapos_app/features/receivables/presentation/screens/detalle_cuenta_cliente_screen.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';

import '../fakes/receivables_fakes.dart';

final _detalleConMovimientos = CuentaPorCobrarDetalle(
  clienteId: 'cliente-1',
  nombreCliente: 'Cliente E2E',
  rutCliente: '20345911-4',
  saldoActual: 25000,
  movimientos: [
    MovimientoCuentaCliente(
      id: 'mov-1',
      tipo: 'Cargo',
      monto: 30000,
      fechaVencimiento: DateTime(2026, 12, 1),
      motivo: 'Venta venta-1',
      medioPago: null,
      fechaMovimiento: DateTime(2026, 8, 1),
    ),
    MovimientoCuentaCliente(
      id: 'mov-2',
      tipo: 'Abono',
      monto: 5000,
      fechaVencimiento: null,
      motivo: 'Pago parcial',
      medioPago: MedioPago.tarjetaDebito,
      fechaMovimiento: DateTime(2026, 8, 5),
    ),
  ],
);

void main() {
  late FakeReceivablesRepository fakeReceivables;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakeReceivables = FakeReceivablesRepository()..detalleARetornar = _detalleConMovimientos;

    await tester.pumpWidget(ProviderScope(
      overrides: [receivablesRepositoryProvider.overrideWithValue(fakeReceivables)],
      child: const MaterialApp(home: DetalleCuentaClienteScreen(clienteId: 'cliente-1')),
    ));
    await tester.pump();
    await tester.pump();
    // Deja terminar la animación de entrada del FloatingActionButton (recién
    // aparece cuando el detalle termina de cargar) antes de interactuar.
    await tester.pumpAndSettle();
  }

  testWidgets('Muestra el saldo actual y los movimientos con su medio de pago', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Cliente E2E'), findsOneWidget);
    expect(find.text('20345911-4'), findsOneWidget);
    expect(find.text('Cargo'), findsOneWidget);
    expect(find.text('Abono'), findsOneWidget);
    expect(find.textContaining('Tarjeta Débito'), findsOneWidget);
  });

  testWidgets('Registrar un abono llama al repositorio con el medio de pago elegido', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('registrarAbonoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('abonoMonto')), '5000');
    await tester.tap(find.byKey(const Key('abonoMedioPago')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta Crédito').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('abonoConfirmar')));
    await tester.pumpAndSettle();

    expect(fakeReceivables.ultimoMontoAbonado, 5000);
    expect(fakeReceivables.ultimoMedioPagoAbonado, MedioPago.tarjetaCredito);
  });

  testWidgets('Un abono mayor al saldo actual muestra error y no llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('registrarAbonoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('abonoMonto')), '999999');
    await tester.tap(find.byKey(const Key('abonoConfirmar')));
    await tester.pump();

    expect(find.textContaining('no puede superar el saldo'), findsOneWidget);
    expect(fakeReceivables.ultimoMontoAbonado, isNull);
  });
}
