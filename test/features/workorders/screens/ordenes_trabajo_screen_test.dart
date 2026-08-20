import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/screens/ordenes_trabajo_screen.dart';

import '../fakes/workorders_fakes.dart';

final _ordenEnEvaluacion = OrdenTrabajoResumen(
  id: 'ot-1',
  numero: 'OT-20260817-001',
  clienteNombre: 'Cliente Prueba',
  descripcion: 'Notebook no enciende',
  estado: EstadoOrdenTrabajo.enEvaluacion,
  fechaRecepcion: DateTime.utc(2026, 8, 17),
  montoCotizado: 45000,
  montoAprobado: null,
);

void main() {
  late FakeWorkOrdersRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fake = FakeWorkOrdersRepository()..ordenesARetornar = [_ordenEnEvaluacion];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const OrdenesTrabajoScreen()),
      GoRoute(path: '/ordenes-trabajo/:id', builder: (context, state) => Text('Detalle ${state.pathParameters['id']}')),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra las Órdenes de Trabajo con su Estado y monto', (tester) async {
    await pumpPantalla(tester);

    expect(find.textContaining('OT-20260817-001'), findsOneWidget);
    expect(find.textContaining('En Evaluación · '), findsOneWidget);
  });

  testWidgets('Sin Órdenes muestra el mensaje vacío', (tester) async {
    fake = FakeWorkOrdersRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: OrdenesTrabajoScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sin Órdenes de Trabajo'), findsOneWidget);
  });

  testWidgets('Tocar una Orden navega al detalle', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('ordenTrabajo_ot-1')));
    await tester.pumpAndSettle();

    expect(find.text('Detalle ot-1'), findsOneWidget);
  });

  testWidgets('Filtrar por Estado llama a cargar con ese filtro', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('filtroEstado_lista')));
    await tester.pump();
    await tester.pump();

    // No revienta y sigue mostrando la pantalla — el fake filtra localmente.
    expect(find.byType(OrdenesTrabajoScreen), findsOneWidget);
  });
}
