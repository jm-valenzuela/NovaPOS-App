import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/auth/domain/models/sesion_usuario.dart';
import 'package:novapos_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:novapos_app/features/home/presentation/screens/home_screen.dart';
import 'package:novapos_app/features/sales/domain/models/descuento_pendiente.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show salesRepositoryProvider;

import '../../auth/fakes/fake_auth_repository.dart';
import '../../sales/fakes/pos_fakes.dart';

DescuentoPendiente _pendiente(String ventaId) => DescuentoPendiente(
      ventaId: ventaId,
      clienteId: 'cliente-1',
      subtotalLineas: 10000,
      porcentaje: 10,
      monto: null,
      solicitadoPorUsuarioId: 'usuario-1',
      fechaSolicitud: DateTime(2026, 8, 5),
    );

void main() {
  late FakeAuthRepository fakeAuth;
  late FakeSalesRepository fakeSales;

  Future<void> pumpHome(WidgetTester tester, {required List<String> permisos}) async {
    fakeAuth = FakeAuthRepository()
      ..sesionActiva = true
      ..sesionARetornar = SesionUsuario(
        nombreCompleto: 'Ana Pérez',
        email: 'admin@novapos-demo.cl',
        empresaRazonSocial: 'Minimarket Don José SpA',
        permisos: permisos,
      );
    fakeSales = FakeSalesRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Sin el permiso de autorizar descuentos, no muestra la tarjeta ni la burbuja', (tester) async {
    await pumpHome(tester, permisos: []);

    expect(find.text('Descuentos pendientes'), findsNothing);
    expect(find.byKey(const Key('badgeDescuentosPendientes')), findsNothing);
  });

  testWidgets('Con el permiso pero sin pendientes, muestra la tarjeta sin burbuja', (tester) async {
    await pumpHome(tester, permisos: ['sales.descuentos.autorizar']);

    expect(find.text('Descuentos pendientes'), findsOneWidget);
    expect(find.byKey(const Key('badgeDescuentosPendientes')), findsNothing);
  });

  testWidgets('Con pendientes, muestra la burbuja con la cantidad', (tester) async {
    fakeSales = FakeSalesRepository()..pendientesARetornar = [_pendiente('venta-1'), _pendiente('venta-2')];
    fakeAuth = FakeAuthRepository()
      ..sesionActiva = true
      ..sesionARetornar = const SesionUsuario(
        nombreCompleto: 'Ana Pérez',
        email: 'admin@novapos-demo.cl',
        empresaRazonSocial: 'Minimarket Don José SpA',
        permisos: ['sales.descuentos.autorizar'],
      );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('badgeDescuentosPendientes')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Sin permisos de Clientes/Compras, no muestra esas tarjetas', (tester) async {
    await pumpHome(tester, permisos: []);

    expect(find.byKey(const Key('homeClientesCard')), findsNothing);
    expect(find.byKey(const Key('homeComprasCard')), findsNothing);
  });

  testWidgets('Con customers.clientes.gestionar, muestra la tarjeta Clientes', (tester) async {
    await pumpHome(tester, permisos: ['customers.clientes.gestionar']);

    expect(find.byKey(const Key('homeClientesCard')), findsOneWidget);
    expect(find.byKey(const Key('homeComprasCard')), findsNothing);
  });

  testWidgets('Con cualquiera de los permisos de Compras, muestra la tarjeta Compras', (tester) async {
    await pumpHome(tester, permisos: ['purchasing.proveedores.gestionar']);

    expect(find.byKey(const Key('homeComprasCard')), findsOneWidget);

    await pumpHome(tester, permisos: ['purchasing.ordenescompra.gestionar']);

    expect(find.byKey(const Key('homeComprasCard')), findsOneWidget);
  });
}
