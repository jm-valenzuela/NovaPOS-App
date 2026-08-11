import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/auth/domain/models/sesion_usuario.dart';
import 'package:novapos_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:novapos_app/features/customers/domain/models/solicitud_credito_pendiente.dart';
import 'package:novapos_app/features/customers/presentation/screens/clientes_hub_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../auth/fakes/fake_auth_repository.dart';
import '../../sales/fakes/pos_fakes.dart';

Future<void> _pumpHub(WidgetTester tester, {required List<String> permisos, FakeCustomerRepository? fakeCustomer}) async {
  final fakeAuth = FakeAuthRepository()
    ..sesionActiva = true
    ..sesionARetornar = SesionUsuario(
      nombreCompleto: 'Ana Pérez',
      email: 'admin@novapos-demo.cl',
      empresaRazonSocial: 'Minimarket Don José SpA',
      permisos: permisos,
    );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      if (fakeCustomer != null) customerRepositoryProvider.overrideWithValue(fakeCustomer),
    ],
    child: const MaterialApp(home: ClientesHubScreen()),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('Muestra siempre Mantención, Cobranzas y Plazos de Clientes', (tester) async {
    await _pumpHub(tester, permisos: []);

    expect(find.byKey(const Key('clientesMantencionCard')), findsOneWidget);
    expect(find.byKey(const Key('clientesCobranzasCard')), findsOneWidget);
    expect(find.byKey(const Key('clientesPlazosPagoCard')), findsOneWidget);
  });

  testWidgets('Sin el permiso de autorizar credito, no muestra la tarjeta ni la burbuja', (tester) async {
    await _pumpHub(tester, permisos: []);

    expect(find.byKey(const Key('clientesCreditoPendienteCard')), findsNothing);
    expect(find.byKey(const Key('clientesBadgeCreditoPendiente')), findsNothing);
  });

  testWidgets('Con el permiso pero sin solicitudes pendientes, muestra la tarjeta sin burbuja', (tester) async {
    await _pumpHub(
      tester,
      permisos: ['customers.clientes.autorizarcredito'],
      fakeCustomer: FakeCustomerRepository(),
    );

    expect(find.byKey(const Key('clientesCreditoPendienteCard')), findsOneWidget);
    expect(find.byKey(const Key('clientesBadgeCreditoPendiente')), findsNothing);
  });

  testWidgets('Con solicitudes pendientes, muestra la burbuja con la cantidad', (tester) async {
    final fakeCustomer = FakeCustomerRepository()
      ..solicitudesCreditoPendientesARetornar = [
        SolicitudCreditoPendiente(
          clienteId: 'cliente-1',
          clienteNombre: 'Empresa Test',
          clienteRut: '12345678-5',
          cupoCreditoActual: 0,
          cupoCreditoSolicitado: 500000,
          plazoPagoIdSolicitado: 'plazo-1',
          solicitadoPorUsuarioId: 'usuario-1',
          fechaSolicitud: DateTime(2026, 8, 8),
        ),
      ];

    await _pumpHub(tester, permisos: ['customers.clientes.autorizarcredito'], fakeCustomer: fakeCustomer);

    expect(find.byKey(const Key('clientesBadgeCreditoPendiente')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
