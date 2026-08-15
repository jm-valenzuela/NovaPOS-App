import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/venta_para_devolucion_detalle.dart';
import 'package:novapos_app/features/returns/presentation/providers/returns_providers.dart';
import 'package:novapos_app/features/returns/presentation/screens/registrar_devolucion_screen.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show customerRepositoryProvider;

import '../../sales/fakes/pos_fakes.dart';
import '../fakes/returns_fakes.dart';

void main() {
  late FakeReturnsRepository fakeReturns;
  late FakeCustomerRepository fakeCustomer;

  const lineaAguarras = LineaVentaParaDevolucion(
    varianteProductoId: 'variante-1',
    nombreProducto: 'Aguarrás Mineral',
    sku: 'DEMO-FER-AGUARRAS',
    cantidad: 1,
    cantidadYaDevuelta: 0,
    precioUnitario: 2290,
    subtotal: 2290,
  );

  Future<void> pumpScreen(WidgetTester tester, {required bool clienteEsGenerico}) async {
    fakeReturns = FakeReturnsRepository()
      ..detalleARetornar = VentaParaDevolucionDetalle(
        ventaId: 'venta-1',
        clienteId: clienteEsGenerico ? 'cliente-generico' : 'cliente-1',
        clienteNombre: clienteEsGenerico ? 'Cliente Genérico' : 'Juan Pérez',
        clienteRut: clienteEsGenerico ? '66666666-6' : '12345678-5',
        clienteEsGenerico: clienteEsGenerico,
        total: 2290,
        pagadaIntegramenteEnEfectivo: true,
        lineas: [lineaAguarras],
      );
    fakeCustomer = FakeCustomerRepository()
      ..resultadosARetornar = [
        const ClienteResumen(id: 'cliente-real-1', nombre: 'María López', rut: '98765432-1', email: null, telefono: null),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        returnsRepositoryProvider.overrideWithValue(fakeReturns),
        customerRepositoryProvider.overrideWithValue(fakeCustomer),
      ],
      child: const MaterialApp(home: RegistrarDevolucionScreen(ventaId: 'venta-1')),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Con Cliente Genérico, "Elegir Cliente" abre el selector SIN la opción "Usar Cliente Genérico"', (tester) async {
    await pumpScreen(tester, clienteEsGenerico: true);

    expect(find.text('Esta Venta fue del Cliente Genérico — la Nota de Crédito debe quedar a nombre de un Cliente real.'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('devolucionElegirClienteReal')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selectorClienteBusqueda')), findsOneWidget);
    expect(find.byKey(const Key('selectorClienteGenerico')), findsNothing);
  });

  testWidgets('Con Cliente real, no muestra el aviso de Cliente Genérico', (tester) async {
    await pumpScreen(tester, clienteEsGenerico: false);

    expect(find.textContaining('Cliente Genérico'), findsNothing);
    expect(find.byKey(const Key('devolucionElegirClienteReal')), findsNothing);
  });
}
