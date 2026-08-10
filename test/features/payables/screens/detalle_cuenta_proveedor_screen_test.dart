import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/payables/domain/models/cuenta_por_pagar_detalle.dart';
import 'package:novapos_app/features/payables/domain/models/movimiento_cuenta_proveedor.dart';
import 'package:novapos_app/features/payables/presentation/providers/payables_providers.dart';
import 'package:novapos_app/features/payables/presentation/screens/detalle_cuenta_proveedor_screen.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';

import '../fakes/payables_fakes.dart';

final _detalleConMovimientos = CuentaPorPagarDetalle(
  proveedorId: 'proveedor-1',
  nombreProveedor: 'Proveedor E2E',
  rutProveedor: '76543210-3',
  saldoActual: 25000,
  movimientos: [
    MovimientoCuentaProveedor(
      id: 'mov-1',
      tipo: 'Cargo',
      monto: 30000,
      fechaVencimiento: DateTime(2026, 12, 1),
      motivo: 'Factura N° 123',
      medioPago: null,
      fechaMovimiento: DateTime(2026, 8, 1),
    ),
    MovimientoCuentaProveedor(
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
  late FakePayablesRepository fakePayables;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fakePayables = FakePayablesRepository()..detalleARetornar = _detalleConMovimientos;

    await tester.pumpWidget(ProviderScope(
      overrides: [payablesRepositoryProvider.overrideWithValue(fakePayables)],
      child: const MaterialApp(home: DetalleCuentaProveedorScreen(proveedorId: 'proveedor-1')),
    ));
    await tester.pump();
    await tester.pump();
    // Deja terminar la animación de entrada del FloatingActionButton (recién
    // aparece cuando el detalle termina de cargar) antes de interactuar.
    await tester.pumpAndSettle();
  }

  testWidgets('Muestra el saldo actual y los movimientos con su medio de pago', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Proveedor E2E'), findsOneWidget);
    expect(find.text('76543210-3'), findsOneWidget);
    expect(find.text('Cargo'), findsOneWidget);
    expect(find.text('Abono'), findsOneWidget);
    expect(find.textContaining('Tarjeta Débito'), findsOneWidget);
  });

  testWidgets('Registrar un pago llama al repositorio con el medio de pago elegido', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('registrarPagoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pagoMonto')), '5000');
    await tester.tap(find.byKey(const Key('pagoMedioPago')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta Crédito').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pagoConfirmar')));
    await tester.pumpAndSettle();

    expect(fakePayables.ultimoMontoPagado, 5000);
    expect(fakePayables.ultimoMedioPagoPagado, MedioPago.tarjetaCredito);
  });

  testWidgets('Un pago mayor al saldo actual muestra error y no llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('registrarPagoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pagoMonto')), '999999');
    await tester.tap(find.byKey(const Key('pagoConfirmar')));
    await tester.pump();

    expect(find.textContaining('no puede superar el saldo'), findsOneWidget);
    expect(fakePayables.ultimoMontoPagado, isNull);
  });
}
