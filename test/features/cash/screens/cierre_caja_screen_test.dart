import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/cash/domain/models/resumen_cierre_caja.dart';
import 'package:novapos_app/features/cash/presentation/providers/cash_providers.dart';
import 'package:novapos_app/features/cash/presentation/screens/cierre_caja_screen.dart';

import '../fakes/cash_fakes.dart';

void main() {
  late FakeCashRepository fakeCash;

  ResumenCierreCaja resumenAbierto() => ResumenCierreCaja(
        sesionCajaId: 'sesion-1',
        cajaId: 'caja-1',
        montoInicial: 50000,
        totalVentasEfectivo: 100000,
        totalVentasTarjetaDebito: 0,
        totalVentasTarjetaCredito: 0,
        totalVentasCredito: 0,
        totalRetiros: 20000,
        montoEsperado: 130000,
        montoContado: null,
        diferencia: null,
        cerrada: false,
        movimientos: [
          MovimientoCaja(
            tipo: TipoMovimientoCaja.retiro,
            referenciaId: 'retiro-1',
            monto: 20000,
            detalle: 'Mucho efectivo acumulado',
            fecha: DateTime(2026, 8, 11, 10, 30),
          ),
        ],
      );

  Future<void> pumpScreen(WidgetTester tester, {ResumenCierreCaja? resumen}) async {
    fakeCash = FakeCashRepository()..resumenCierreARetornar = resumen ?? resumenAbierto();

    await tester.pumpWidget(ProviderScope(
      overrides: [cashRepositoryProvider.overrideWithValue(fakeCash)],
      child: const MaterialApp(home: CierreCajaScreen(sesionCajaId: 'sesion-1')),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra el resumen con monto inicial, ventas, retiros y esperado', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining(r'$50.000'), findsWidgets);
    expect(find.textContaining(r'$100.000'), findsOneWidget);
    expect(find.textContaining(r'$130.000'), findsWidgets);
    expect(find.text('Sesión Abierta'), findsOneWidget);
  });

  testWidgets('Muestra la lista de movimientos', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Retiro'), findsOneWidget);
    expect(find.textContaining('Mucho efectivo acumulado'), findsOneWidget);
  });

  testWidgets('Cerrar Caja con el monto contado llama al repositorio', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('cierreCajaMontoContado')), '128000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('cierreCajaConfirmar')));
    await tester.pump();
    await tester.pump();

    expect(fakeCash.ultimoSesionIdCerrado, 'sesion-1');
    expect(fakeCash.ultimoMontoContado, 128000);
    expect(find.text('Sesión Cerrada'), findsOneWidget);
  });
}
