import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/widgets/registrar_anticipo_dialog.dart';

import '../fakes/workorders_fakes.dart';

void main() {
  late FakeWorkOrdersRepository fake;

  Future<void> abrirDialogo(WidgetTester tester, {double saldoDisponible = 50000}) async {
    fake = FakeWorkOrdersRepository()
      ..detalleARetornar = OrdenTrabajoDetalle(
        id: 'ot-1',
        numero: 'OT-20260820-001',
        clienteId: 'cliente-1',
        clienteNombre: 'Cliente Prueba',
        clienteRut: null,
        sucursalId: 'sucursal-1',
        descripcion: 'Cambio de neumáticos',
        estado: EstadoOrdenTrabajo.enEjecucion,
        fechaRecepcion: DateTime.utc(2026, 8, 20),
        items: [],
        montoCotizado: 50000,
        montoAprobado: 50000,
        fechaEntrega: null,
        ventaId: null,
      );

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => RegistrarAnticipoDialog(
                ordenTrabajoId: 'ot-1',
                sesionCajaId: 'sesion-1',
                numeroOrden: 'OT-20260820-001',
                clienteNombre: 'Cliente Prueba',
                saldoDisponible: saldoDisponible,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Sin monto ingresado muestra error y no llama al repositorio', (tester) async {
    await abrirDialogo(tester);

    await tester.tap(find.byKey(const Key('anticipoConfirmar')));
    await tester.pump();

    expect(find.textContaining('Ingresa un monto mayor a cero'), findsOneWidget);
    expect(fake.ultimoMontoAnticipo, isNull);
  });

  testWidgets('Con un monto mayor al saldo disponible muestra error y no llama al repositorio', (tester) async {
    await abrirDialogo(tester, saldoDisponible: 50000);

    await tester.enterText(find.byKey(const Key('anticipoMonto')), '60000');
    await tester.tap(find.byKey(const Key('anticipoConfirmar')));
    await tester.pump();

    expect(find.textContaining('no puede superar el saldo pendiente'), findsOneWidget);
    expect(fake.ultimoMontoAnticipo, isNull);
  });
}
