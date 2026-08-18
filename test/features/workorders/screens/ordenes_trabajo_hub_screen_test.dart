import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/screens/ordenes_trabajo_hub_screen.dart';

import '../fakes/workorders_fakes.dart';

void main() {
  Future<void> pumpHub(WidgetTester tester) async {
    final fake = FakeWorkOrdersRepository();

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const OrdenesTrabajoHubScreen()),
      GoRoute(path: '/ordenes-trabajo/listado', builder: (context, state) => const Text('Listado')),
      GoRoute(path: '/ordenes-trabajo/operarios', builder: (context, state) => const Text('Operarios')),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
  }

  testWidgets('Muestra las tarjetas de Órdenes de Trabajo y Operarios', (tester) async {
    await pumpHub(tester);

    expect(find.byKey(const Key('ordenesTrabajoListadoCard')), findsOneWidget);
    expect(find.byKey(const Key('ordenesTrabajoOperariosCard')), findsOneWidget);
  });

  testWidgets('Tocar la tarjeta de Operarios navega a /ordenes-trabajo/operarios', (tester) async {
    await pumpHub(tester);

    await tester.tap(find.byKey(const Key('ordenesTrabajoOperariosCard')));
    await tester.pumpAndSettle();

    expect(find.text('Operarios'), findsOneWidget);
  });

  testWidgets('Tocar la tarjeta de Órdenes de Trabajo navega a /ordenes-trabajo/listado', (tester) async {
    await pumpHub(tester);

    await tester.tap(find.byKey(const Key('ordenesTrabajoListadoCard')));
    await tester.pumpAndSettle();

    expect(find.text('Listado'), findsOneWidget);
  });
}
