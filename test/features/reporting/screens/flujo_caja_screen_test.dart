import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/reporting/domain/models/flujo_caja_dia.dart';
import 'package:novapos_app/features/reporting/presentation/providers/reporting_providers.dart';
import 'package:novapos_app/features/reporting/presentation/screens/flujo_caja_screen.dart';

import '../fakes/reporting_fakes.dart';

final _dias = [
  FlujoCajaDia(
    fecha: DateTime(2026, 8, 1),
    entradaReal: 111000,
    salidaReal: 41000,
    flujoNetoReal: 70000,
    entradaProyectada: 21000,
    salidaProyectada: 1000,
    flujoNetoProyectado: 20000,
  ),
  FlujoCajaDia(
    fecha: DateTime(2026, 8, 2),
    entradaReal: 32000,
    salidaReal: 52000,
    flujoNetoReal: -20000,
    entradaProyectada: 2000,
    salidaProyectada: 12000,
    flujoNetoProyectado: -10000,
  ),
];

void main() {
  late FakeReportingRepository fakeReporting;

  Future<void> pumpPantalla(WidgetTester tester, {List<FlujoCajaDia>? dias}) async {
    fakeReporting = FakeReportingRepository()..flujoCajaARetornar = dias ?? _dias;

    await tester.pumpWidget(ProviderScope(
      overrides: [reportingRepositoryProvider.overrideWithValue(fakeReporting)],
      child: const MaterialApp(home: FlujoCajaScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la grilla con Ingresos/Egresos/Neto Real y Proyectado por día', (tester) async {
    await pumpPantalla(tester);

    expect(find.byKey(const Key('grillaFlujoCaja')), findsOneWidget);
    expect(find.text('\$111.000'), findsOneWidget);
    expect(find.text('\$41.000'), findsOneWidget);
    expect(find.text('01-08-2026'), findsOneWidget);
    expect(find.text('02-08-2026'), findsOneWidget);
  });

  testWidgets('La fila de totales suma correctamente cada columna', (tester) async {
    await pumpPantalla(tester);

    // Entrada Real total: 111000 + 32000 = 143000; Neto Real total: 70000 + (-20000) = 50000.
    expect(find.text('\$143.000'), findsOneWidget);
    expect(find.text('\$50.000'), findsOneWidget);
  });

  testWidgets('Sin movimientos en el período, muestra el mensaje vacío', (tester) async {
    await pumpPantalla(tester, dias: []);

    expect(find.textContaining('Sin movimientos en el período'), findsOneWidget);
    expect(find.byKey(const Key('grillaFlujoCaja')), findsNothing);
  });

  testWidgets('Consulta el backend con el período por defecto (mes en curso hasta hoy)', (tester) async {
    await pumpPantalla(tester);

    final ahora = DateTime.now();
    expect(fakeReporting.ultimoDesdeConsultado, DateTime(ahora.year, ahora.month, 1));
    expect(fakeReporting.ultimoHastaConsultado, DateTime(ahora.year, ahora.month, ahora.day));
  });
}
