import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/sales/domain/models/descuento_pendiente.dart';
import 'package:novapos_app/features/sales/domain/models/detalle_descuento_pendiente.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/sales/presentation/screens/descuentos_pendientes_screen.dart';

import '../fakes/pos_fakes.dart';

void main() {
  late FakeSalesRepository fakeSales;

  final pendiente = DescuentoPendiente(
    ventaId: 'venta-1',
    clienteId: 'cliente-1',
    subtotalLineas: 10000,
    porcentaje: 10,
    monto: null,
    solicitadoPorUsuarioId: 'usuario-1',
    fechaSolicitud: DateTime(2026, 8, 4),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    fakeSales = FakeSalesRepository()..pendientesARetornar = [pendiente];

    await tester.pumpWidget(ProviderScope(
      overrides: [salesRepositoryProvider.overrideWithValue(fakeSales)],
      child: const MaterialApp(home: DescuentosPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra la lista de descuentos pendientes', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Subtotal: \$10.000'), findsOneWidget);
    expect(find.textContaining('10% de descuento'), findsOneWidget);
  });

  testWidgets('Autorizar llama al repositorio y recarga la lista', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('descuentoPendienteAutorizar_venta-1')));
    await tester.pump();
    await tester.pump();

    expect(fakeSales.ultimaVentaIdAutorizada, 'venta-1');
  });

  testWidgets('Rechazar pide un motivo y lo manda al repositorio', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('descuentoPendienteRechazar_venta-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rechazarDescuentoMotivo')), 'Monto muy alto');
    await tester.tap(find.byKey(const Key('rechazarDescuentoConfirmar')));
    await tester.pump();
    await tester.pump();

    expect(fakeSales.ultimaVentaIdRechazada, 'venta-1');
    expect(fakeSales.ultimoMotivoRechazo, 'Monto muy alto');
  });

  testWidgets('Ver más expande y muestra Cliente y Productos', (tester) async {
    await pumpScreen(tester);
    fakeSales.detalleDescuentoARetornar = const DetalleDescuentoPendiente(
      ventaId: 'venta-1',
      clienteId: 'cliente-1',
      clienteNombre: 'Juan Pérez',
      clienteRut: '76.123.456-0',
      subtotalLineas: 10000,
      porcentaje: 10,
      monto: null,
      lineas: [
        LineaDescuentoPendienteDetalle(
          varianteProductoId: 'variante-1',
          nombreProducto: 'Coca Cola 1.5L',
          sku: 'COCA-15',
          cantidad: 2,
          precioUnitario: 1500,
          subtotal: 3000,
        ),
      ],
    );

    expect(find.byKey(const Key('descuentoPendienteDetalle_venta-1')), findsNothing);

    await tester.tap(find.byKey(const Key('descuentoPendienteVerMas_venta-1')));
    await tester.pump();
    await tester.pump();

    expect(fakeSales.ultimaVentaIdDetalleConsultada, 'venta-1');
    expect(find.byKey(const Key('descuentoPendienteDetalle_venta-1')), findsOneWidget);
    expect(find.textContaining('Juan Pérez'), findsOneWidget);
    expect(find.textContaining('76.123.456-0'), findsOneWidget);
    expect(find.textContaining('2 × Coca Cola 1.5L'), findsOneWidget);
    expect(find.text('Ver menos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('descuentoPendienteVerMas_venta-1')));
    await tester.pump();

    expect(find.byKey(const Key('descuentoPendienteDetalle_venta-1')), findsNothing);
    expect(find.text('Ver más — Cliente y Productos'), findsOneWidget);
  });

  testWidgets('Sin pendientes, muestra el mensaje vacío', (tester) async {
    fakeSales = FakeSalesRepository()..pendientesARetornar = [];
    await tester.pumpWidget(ProviderScope(
      overrides: [salesRepositoryProvider.overrideWithValue(fakeSales)],
      child: const MaterialApp(home: DescuentosPendientesScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No hay descuentos pendientes'), findsOneWidget);
  });
}
