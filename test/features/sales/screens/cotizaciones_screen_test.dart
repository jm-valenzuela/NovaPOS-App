import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/sales/domain/models/cotizacion.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart';
import 'package:novapos_app/features/sales/presentation/screens/cotizaciones_screen.dart';

import '../fakes/pos_fakes.dart';

void main() {
  late FakeTenancyRepository fakeTenancy;
  late FakeSalesRepository fakeSales;

  final cotizacion1 = CotizacionResumen(
    ventaId: 'venta-cot-1',
    numeroCotizacion: 'COT-20260811-001',
    fechaVenta: DateTime(2026, 8, 11, 10, 30),
    clienteId: 'cliente-juan',
    clienteNombre: 'Juan Pérez',
    cantidadLineas: 2,
    total: 5000,
  );

  final cotizacion2 = CotizacionResumen(
    ventaId: 'venta-cot-2',
    numeroCotizacion: 'COT-20260811-002',
    fechaVenta: DateTime(2026, 8, 11, 11, 0),
    clienteId: 'cliente-generico',
    clienteNombre: 'Cliente Genérico',
    cantidadLineas: 1,
    total: 1500,
  );

  Future<void> pumpScreen(WidgetTester tester, {List<CotizacionResumen>? cotizaciones}) async {
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()..cotizacionesARetornar = cotizaciones ?? [cotizacion1, cotizacion2];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: CotizacionesScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Con una sola Sucursal, la elige automáticamente y muestra la lista', (tester) async {
    await pumpScreen(tester);

    expect(fakeSales.ultimaSucursalIdCotizacionesConsultada, cajaUnica.sucursalId);
    expect(find.textContaining('COT-20260811-001 · Juan Pérez'), findsOneWidget);
    expect(find.textContaining('COT-20260811-002 · Cliente Genérico'), findsOneWidget);
  });

  testWidgets('Buscar filtra por número de Cotización', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('cotizacionesBuscar')), '002');
    await tester.pump();

    expect(find.textContaining('COT-20260811-001'), findsNothing);
    expect(find.textContaining('COT-20260811-002'), findsOneWidget);
  });

  testWidgets('Buscar filtra por nombre de Cliente', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('cotizacionesBuscar')), 'juan');
    await tester.pump();

    expect(find.textContaining('COT-20260811-001'), findsOneWidget);
    expect(find.textContaining('COT-20260811-002'), findsNothing);
  });

  testWidgets('Sin Cotizaciones, muestra el mensaje vacío', (tester) async {
    await pumpScreen(tester, cotizaciones: []);

    expect(find.textContaining('No hay Cotizaciones guardadas'), findsOneWidget);
  });

  testWidgets('Tocar una Cotización abre el detalle con sus líneas y total', (tester) async {
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()
      ..cotizacionesARetornar = [cotizacion1]
      ..cotizacionDetalleARetornar = const CotizacionDetalle(
        ventaId: 'venta-cot-1',
        numeroCotizacion: 'COT-20260811-001',
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        clienteRut: '76.123.456-0',
        subtotalLineas: 5000,
        total: 5000,
        estadoDescuentoGeneral: EstadoDescuentoGeneral.sinSolicitar,
        descuentoGeneralPorcentaje: null,
        descuentoGeneralMonto: null,
        lineas: [
          LineaCotizacionDetalle(
            lineaVentaId: 'linea-1',
            varianteProductoId: 'variante-1',
            nombreProducto: 'Coca-Cola 1.5L',
            sku: 'SKU-1',
            cantidad: 2,
            precioUnitario: 2500,
            subtotal: 5000,
          ),
        ],
      );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: CotizacionesScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('cotizacionItem_venta-cot-1')));
    await tester.pumpAndSettle();

    expect(find.text('Coca-Cola 1.5L'), findsOneWidget);
    expect(find.text('2 x \$2.500'), findsOneWidget);
    expect(find.text('Cliente: Juan Pérez · 76.123.456-0'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('IVA (19%)'), findsOneWidget);
    expect(fakeSales.ultimaVentaIdCotizacionConsultada, 'venta-cot-1');
  });

  testWidgets('El detalle muestra el Descuento general, la Oferta y la promoción por grupo aplicados', (tester) async {
    fakeTenancy = FakeTenancyRepository()..cajasARetornar = [cajaUnica];
    fakeSales = FakeSalesRepository()
      ..cotizacionesARetornar = [cotizacion1]
      ..cotizacionDetalleARetornar = const CotizacionDetalle(
        ventaId: 'venta-cot-1',
        numeroCotizacion: 'COT-20260811-001',
        clienteId: 'cliente-juan',
        clienteNombre: 'Juan Pérez',
        clienteRut: '76.123.456-0',
        subtotalLineas: 700000,
        total: 662411,
        estadoDescuentoGeneral: EstadoDescuentoGeneral.autorizado,
        descuentoGeneralPorcentaje: 2,
        descuentoGeneralMonto: null,
        lineas: [
          LineaCotizacionDetalle(
            lineaVentaId: 'linea-1',
            varianteProductoId: 'variante-oferta',
            nombreProducto: 'Producto Test Oferta E2E',
            sku: 'SKU-OFERTA',
            cantidad: 1,
            precioUnitario: 399990,
            subtotal: 399990,
            precioOferta: 399990,
            precioVenta: 500000,
          ),
          LineaCotizacionDetalle(
            lineaVentaId: 'linea-2',
            varianteProductoId: 'variante-4x3',
            nombreProducto: 'Neumático 175/65 R14',
            sku: 'SKU-4X3',
            cantidad: 8,
            precioUnitario: 45990,
            subtotal: 275940,
            montoDescuentoPromocion: 45990,
            cantidadPorGrupoPromocion: 4,
            porcentajeDescuentoUnidadPromocion: 100,
          ),
        ],
      );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tenancyRepositoryProvider.overrideWithValue(fakeTenancy),
        salesRepositoryProvider.overrideWithValue(fakeSales),
      ],
      child: const MaterialApp(home: CotizacionesScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('cotizacionItem_venta-cot-1')));
    await tester.pumpAndSettle();

    expect(find.text('Oferta aplicada'), findsOneWidget);
    expect(find.text('4x3 aplicado'), findsOneWidget);
    expect(find.text('Descuento (2%)'), findsOneWidget);
    expect(find.text('\$500.000'), findsOneWidget);
  });
}
