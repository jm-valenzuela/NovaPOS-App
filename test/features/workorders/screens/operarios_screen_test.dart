import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/screens/operarios_screen.dart';

import '../fakes/workorders_fakes.dart';

const _activo = UsuarioResumen(id: 'usuario-1', nombreCompleto: 'Juan Pérez', email: 'juan@novapos-demo.cl', rolesNombres: ['Cajero'], activo: true);
const _inactivo = UsuarioResumen(id: 'usuario-2', nombreCompleto: 'Ana Soto', email: 'ana@novapos-demo.cl', rolesNombres: ['Bodeguero'], activo: false);

void main() {
  late FakeWorkOrdersRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    fake = FakeWorkOrdersRepository()..usuariosARetornar = [_activo, _inactivo];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const OperariosScreen()),
      GoRoute(path: '/ordenes-trabajo/:id', builder: (context, state) => Text('Detalle ${state.pathParameters['id']}')),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Lista Operarios activos e inactivos con su badge', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.byKey(const Key('operarioDesactivar_usuario-1')), findsOneWidget);
    expect(find.text('Ana Soto'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('Desactivar pide confirmación y llama al repositorio', (tester) async {
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('operarioDesactivar_usuario-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmarDesactivarOperario')));
    await tester.pumpAndSettle();

    expect(fake.ultimoUsuarioIdDesactivado, 'usuario-1');
  });

  testWidgets('Ver lo asignado muestra los Ítems abiertos por Operario y navega al tocarlos', (tester) async {
    fake = FakeWorkOrdersRepository()
      ..usuariosARetornar = [_activo]
      ..cargaARetornar = [
        const OperarioConCarga(usuarioId: 'usuario-1', nombreCompleto: 'Juan Pérez', items: [
          ItemAsignadoResumen(
            ordenTrabajoId: 'ot-1',
            numeroOrdenTrabajo: 'OT-20260817-001',
            itemId: 'item-1',
            descripcion: 'Cambio de aceite',
            estado: EstadoItemOrdenTrabajo.enTrabajo,
          ),
        ]),
      ];

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const OperariosScreen()),
      GoRoute(path: '/ordenes-trabajo/:id', builder: (context, state) => Text('Detalle ${state.pathParameters['id']}')),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('operariosVerCargaBoton')));
    await tester.pumpAndSettle();

    expect(find.text('Cambio de aceite'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cargaItem_item-1')));
    await tester.pumpAndSettle();

    expect(find.text('Detalle ot-1'), findsOneWidget);
  });
}
