import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/plazo_pago.dart';
import 'package:novapos_app/features/customers/domain/models/solicitud_credito_pendiente.dart';
import 'package:novapos_app/features/customers/presentation/screens/solicitudes_credito_pendientes_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';

void main() {
  late FakeCustomerRepository fakeCustomer;

  final pendiente = SolicitudCreditoPendiente(
    clienteId: 'cliente-1',
    clienteNombre: 'Empresa Test',
    clienteRut: '12.345.678-5',
    cupoCreditoActual: 0,
    cupoCreditoSolicitado: 500000,
    plazoPagoIdSolicitado: 'plazo-1',
    solicitadoPorUsuarioId: 'usuario-1',
    fechaSolicitud: DateTime(2026, 8, 8),
  );

  const plazo30Dias = PlazoPago(
    id: 'plazo-1',
    nombre: '30 días',
    activo: true,
    cuotas: [CuotaPlazoPago(numeroCuota: 1, diasVencimiento: 30)],
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    fakeCustomer = FakeCustomerRepository()
      ..solicitudesCreditoPendientesARetornar = [pendiente]
      ..plazosPagoARetornar = [plazo30Dias];

    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: SolicitudesCreditoPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de solicitudes pendientes', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Empresa Test · 12.345.678-5'), findsOneWidget);
    expect(find.textContaining('Cupo actual: \$0'), findsOneWidget);
    expect(find.textContaining('Cupo solicitado: \$500.000 · 30 días'), findsOneWidget);
  });

  testWidgets('Autorizar llama al repositorio y recarga la lista', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('creditoPendienteAutorizar_cliente-1')));
    await tester.pump();
    await tester.pump();

    expect(fakeCustomer.ultimoClienteIdCreditoAutorizado, 'cliente-1');
  });

  testWidgets('Rechazar pide un motivo y lo manda al repositorio', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('creditoPendienteRechazar_cliente-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rechazarCreditoMotivo')), 'Sin referencias comerciales');
    await tester.tap(find.byKey(const Key('rechazarCreditoConfirmar')));
    await tester.pump();
    await tester.pump();

    expect(fakeCustomer.ultimoClienteIdCreditoRechazado, 'cliente-1');
    expect(fakeCustomer.ultimoMotivoRechazoCredito, 'Sin referencias comerciales');
  });

  testWidgets('Sin pendientes, muestra el mensaje vacío', (tester) async {
    fakeCustomer = FakeCustomerRepository()..solicitudesCreditoPendientesARetornar = [];
    await tester.pumpWidget(ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(fakeCustomer)],
      child: const MaterialApp(home: SolicitudesCreditoPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No hay solicitudes de crédito pendientes'), findsOneWidget);
  });
}
