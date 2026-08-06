import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:novapos_app/features/purchasing/domain/models/orden_compra.dart';
import 'package:novapos_app/features/purchasing/domain/models/purchasing_enums.dart';
import 'package:novapos_app/features/purchasing/presentation/providers/purchasing_providers.dart';
import 'package:novapos_app/features/purchasing/presentation/screens/ordenes_compra_screen.dart';

import '../fakes/purchasing_fakes.dart';

OrdenCompraResumenListado _orden({required String id, required EstadoOrdenCompra estado}) => OrdenCompraResumenListado(
      id: id,
      proveedorId: 'proveedor-1',
      proveedorNombre: 'Distribuidora Central',
      estado: estado,
      total: 15000,
      fechaCreacionOrden: DateTime(2026, 8, 1),
      fechaEnvio: null,
      fechaRecepcion: null,
    );

void main() {
  late FakePurchasingRepository fakePurchasing;

  Future<void> pumpOrdenes(WidgetTester tester) async {
    fakePurchasing = FakePurchasingRepository()
      ..ordenesARetornar = [_orden(id: 'orden-1', estado: EstadoOrdenCompra.borrador)];

    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (context, state) => const OrdenesCompraScreen()),
      GoRoute(path: '/compras/ordenes/:id', builder: (context, state) => const Scaffold(body: Text('Detalle'))),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [purchasingRepositoryProvider.overrideWithValue(fakePurchasing)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra el listado de Órdenes de Compra', (tester) async {
    await pumpOrdenes(tester);

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.textContaining('Borrador'), findsWidgets);
  });

  testWidgets('Elegir un filtro de Estado recarga con ese filtro', (tester) async {
    await pumpOrdenes(tester);

    await tester.tap(find.byKey(const Key('filtroEstado_enviada')));
    await tester.pump();

    expect(fakePurchasing.ultimoFiltroEstado, EstadoOrdenCompra.enviada);
  });

  testWidgets('Tocar una Orden navega al detalle', (tester) async {
    await pumpOrdenes(tester);

    await tester.tap(find.text('Distribuidora Central'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsOneWidget);
  });
}
