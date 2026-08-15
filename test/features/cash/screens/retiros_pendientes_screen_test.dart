import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/cash/domain/models/retiro_caja_pendiente.dart';
import 'package:novapos_app/features/cash/presentation/providers/cash_providers.dart';
import 'package:novapos_app/features/cash/presentation/screens/retiros_pendientes_screen.dart';

import '../fakes/cash_fakes.dart';

void main() {
  late FakeCashRepository fakeCash;

  final pendiente = RetiroCajaPendiente(
    id: 'retiro-1',
    sesionCajaId: 'sesion-1',
    monto: 20000,
    motivo: 'Mucho efectivo acumulado',
    solicitadoPorUsuarioId: 'usuario-1',
    fechaSolicitud: DateTime(2026, 8, 11, 10, 30),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    fakeCash = FakeCashRepository()..retirosPendientesARetornar = [pendiente];

    await tester.pumpWidget(ProviderScope(
      overrides: [cashRepositoryProvider.overrideWithValue(fakeCash)],
      child: const MaterialApp(home: RetirosPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de retiros pendientes', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining(r'$20.000'), findsOneWidget);
    expect(find.textContaining('Mucho efectivo acumulado'), findsOneWidget);
  });

  testWidgets('Autorizar llama al repositorio y recarga la lista', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('retiroPendienteAutorizar_retiro-1')));
    await tester.pump();
    await tester.pump();

    expect(fakeCash.ultimoRetiroIdAutorizado, 'retiro-1');
  });

  testWidgets('Rechazar pide un motivo y lo manda al repositorio', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('retiroPendienteRechazar_retiro-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rechazarRetiroMotivo')), 'No corresponde');
    await tester.tap(find.byKey(const Key('rechazarRetiroConfirmar')));
    await tester.pump();
    await tester.pump();

    expect(fakeCash.ultimoRetiroIdRechazado, 'retiro-1');
    expect(fakeCash.ultimoMotivoRechazoRetiro, 'No corresponde');
  });

  testWidgets('Sin pendientes, muestra el mensaje vacío', (tester) async {
    fakeCash = FakeCashRepository()..retirosPendientesARetornar = [];
    await tester.pumpWidget(ProviderScope(
      overrides: [cashRepositoryProvider.overrideWithValue(fakeCash)],
      child: const MaterialApp(home: RetirosPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No hay Retiros de Caja pendientes'), findsOneWidget);
  });
}
