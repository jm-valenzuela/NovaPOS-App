import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/presentation/screens/clientes_hub_screen.dart';

void main() {
  testWidgets('Muestra Mantención, Cuentas x Cobrar y Plazos de Clientes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ClientesHubScreen())));

    expect(find.byKey(const Key('clientesMantencionCard')), findsOneWidget);
    expect(find.byKey(const Key('clientesCuentasPorCobrarCard')), findsOneWidget);
    expect(find.byKey(const Key('clientesPlazosPagoCard')), findsOneWidget);
    expect(find.text('Cuentas x Cobrar'), findsOneWidget);
  });
}
