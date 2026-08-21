import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/nota_credito_cliente_resumen.dart';
import 'package:novapos_app/features/returns/presentation/providers/returns_providers.dart';
import 'package:novapos_app/features/sales/domain/models/anticipo_disponible_para_pago.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/widgets/checkout_dialog.dart';

import '../../returns/fakes/returns_fakes.dart';

const _clienteCompleto = ClienteResumen(
  id: 'cliente-1',
  rut: '76192083-9',
  nombre: 'Empresa Cliente SpA',
  email: null,
  telefono: null,
  giro: 'Venta al por menor',
  direccion: 'Av. Siempre Viva 123',
  comuna: 'Providencia',
);

const _clienteSinDatos = ClienteResumen(
  id: 'cliente-2',
  rut: null,
  nombre: 'Cliente Genérico',
  email: null,
  telefono: null,
);

void main() {
  // Holder mutable — el resultado real solo se conoce después de cerrar el
  // diálogo (Confirmar), así que los tests que lo necesitan lo leen de acá
  // tras tocar "checkoutConfirmar" y hacer pumpAndSettle.
  final resultadoObtenido = <ResultadoCheckout?>[null];

  Future<void> abrirDialogo(
    WidgetTester tester, {
    required double total,
    required FormaPago formaPago,
    ClienteResumen? cliente,
  }) async {
    resultadoObtenido[0] = null;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resultadoObtenido[0] = await showDialog<ResultadoCheckout>(
                context: context,
                builder: (_) => CheckoutDialog(total: total, formaPago: formaPago, clienteSeleccionado: cliente),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Factura está deshabilitada sin Cliente seleccionado', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: null);

    final segmento = tester.widget<SegmentedButton<TipoDocumento>>(find.byKey(const Key('checkoutTipoDocumento')));
    final factura = segmento.segments.firstWhere((s) => s.value == TipoDocumento.factura);
    expect(factura.enabled, isFalse);
  });

  testWidgets('Factura está habilitada con un Cliente con datos completos', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: _clienteCompleto);

    final segmento = tester.widget<SegmentedButton<TipoDocumento>>(find.byKey(const Key('checkoutTipoDocumento')));
    final factura = segmento.segments.firstWhere((s) => s.value == TipoDocumento.factura);
    expect(factura.enabled, isTrue);
  });

  testWidgets('Factura sigue deshabilitada con un Cliente sin RUT/datos de facturación', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: _clienteSinDatos);

    final segmento = tester.widget<SegmentedButton<TipoDocumento>>(find.byKey(const Key('checkoutTipoDocumento')));
    final factura = segmento.segments.firstWhere((s) => s.value == TipoDocumento.factura);
    expect(factura.enabled, isFalse);
  });

  testWidgets('Al Contado, Confirmar queda deshabilitado hasta que los pagos cuadren con el Total', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: null);

    var boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNull, reason: 'sin monto ingresado, los pagos no cuadran');

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '1000');
    await tester.pump();

    boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('El campo Monto agrupa los miles en vivo mientras se tipea', (tester) async {
    await abrirDialogo(tester, total: 199980, formaPago: FormaPago.contado, cliente: null);

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '199980');
    await tester.pump();

    final montoField = tester.widget<TextField>(find.byKey(const Key('checkoutMonto_0')));
    expect(montoField.controller!.text, '199.980');
  });

  testWidgets('A Crédito, no se muestra la sección de medio de pago y Confirmar queda habilitado', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.credito, cliente: null);

    expect(find.byKey(const Key('checkoutMedioPago_0')), findsNothing);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('Pago mixto: dos medios de pago que juntos cuadran con el Total habilitan Confirmar', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: null);

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '400');
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkoutAgregarPago')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('checkoutMonto_1')), '600');
    await tester.pump();

    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('Efectivo por sobre el Total muestra el Vuelto y habilita Confirmar', (tester) async {
    await abrirDialogo(tester, total: 8982, formaPago: FormaPago.contado, cliente: null);

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '10000');
    await tester.pump();

    expect(find.text('Vuelto: \$1.018'), findsWidgets);
    expect(find.byKey(const Key('checkoutVueltoArriba')), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('El vuelto no se envía como parte del pago — el monto en Efectivo se recorta al Total', (tester) async {
    await abrirDialogo(tester, total: 8982, formaPago: FormaPago.contado, cliente: null);

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '10000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkoutConfirmar')));
    await tester.pumpAndSettle();

    final resultado = resultadoObtenido[0]!;
    expect(resultado.pagos, hasLength(1));
    expect(resultado.pagos.single.medioPago, MedioPago.efectivo);
    expect(resultado.pagos.single.monto, 8982);
  });

  testWidgets('Un Total con resto de coma flotante (ej. de un % de descuento) no genera Vuelto falso en Efectivo',
      (tester) async {
    // 257823.6 redondea a "$257.824" al mostrarse (MonedaFormatter) — el
    // Cajero solo puede tipear pesos enteros, así que tipea exactamente lo
    // que ve. Antes de este fix, comparar contra el total SIN redondear
    // hacía que sobraran 0.4 y se mostrara "Vuelto: $1" al pagar el monto
    // justo mostrado en pantalla.
    await abrirDialogo(tester, total: 257823.6, formaPago: FormaPago.contado, cliente: null);

    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '257824');
    await tester.pump();

    expect(find.textContaining('Vuelto'), findsNothing);
    expect(find.text('Los pagos cuadran con el Total.'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('Un Total con resto de coma flotante no rechaza el monto exacto mostrado en Tarjeta', (tester) async {
    // Mismo caso que el de Efectivo, pero con Tarjeta: antes de este fix,
    // el mismo resto de 0.4 hacía que 257824 se viera como "por sobre el
    // Total" y mostrara "no puede superar el Total" pagando el monto justo.
    await abrirDialogo(tester, total: 257823.6, formaPago: FormaPago.contado, cliente: null);

    await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta Débito').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '257824');
    await tester.pump();

    expect(find.textContaining('no puede superar el Total'), findsNothing);
    expect(find.text('Los pagos cuadran con el Total.'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('Tarjeta por sobre el Total NO da vuelto — Confirmar sigue deshabilitado', (tester) async {
    await abrirDialogo(tester, total: 1000, formaPago: FormaPago.contado, cliente: null);

    await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta Débito').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '1500');
    await tester.pump();

    expect(find.textContaining('no puede superar el Total'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Pago mixto Tarjeta + Efectivo con vuelto: el vuelto se descuenta solo del Efectivo', (tester) async {
    await abrirDialogo(tester, total: 8982, formaPago: FormaPago.contado, cliente: null);

    await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta Débito').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('checkoutMonto_0')), '5000');
    await tester.pump();

    await tester.tap(find.byKey(const Key('checkoutAgregarPago')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('checkoutMonto_1')), '5000'); // efectivo, sobran $1.018
    await tester.pump();

    expect(find.text('Vuelto: \$1.018'), findsWidgets);
    expect(find.byKey(const Key('checkoutVueltoArriba')), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkoutConfirmar')));
    await tester.pumpAndSettle();

    final resultado = resultadoObtenido[0]!;
    expect(resultado.pagos, hasLength(2));
    final tarjeta = resultado.pagos.firstWhere((p) => p.medioPago == MedioPago.tarjetaDebito);
    final efectivo = resultado.pagos.firstWhere((p) => p.medioPago == MedioPago.efectivo);
    expect(tarjeta.monto, 5000);
    expect(efectivo.monto, 3982);
    expect(tarjeta.monto + efectivo.monto, 8982);
  });

  group('Nota de Crédito como medio de pago', () {
    late FakeReturnsRepository fake;

    Future<void> abrirDialogoConNotas(
      WidgetTester tester, {
      required double total,
      ClienteResumen? cliente,
    }) async {
      resultadoObtenido[0] = null;
      await tester.pumpWidget(ProviderScope(
        overrides: [returnsRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultadoObtenido[0] = await showDialog<ResultadoCheckout>(
                  context: context,
                  builder: (_) => CheckoutDialog(total: total, formaPago: FormaPago.contado, clienteSeleccionado: cliente),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    setUp(() => fake = FakeReturnsRepository());

    testWidgets('sin Cliente seleccionado, Nota de Crédito no aparece como opción', (tester) async {
      await abrirDialogoConNotas(tester, total: 1000, cliente: null);

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();

      expect(find.text('Nota de Crédito'), findsNothing);
    });

    testWidgets('con Cliente seleccionado, elegir una Nota fija el Monto a su valor íntegro', (tester) async {
      fake.notasARetornar = [
        NotaCreditoClienteResumen(
          id: 'nota-1',
          folio: 'NC-20260813-001',
          montoTotal: 1000,
          estado: EstadoNotaCreditoCliente.disponible,
          fechaEmision: DateTime(2026, 8, 13),
          motivo: 'Devolución',
        ),
      ];
      await abrirDialogoConNotas(tester, total: 1000, cliente: _clienteCompleto);

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nota de Crédito').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkoutNotaCredito_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NC-20260813-001 · \$1.000').last);
      await tester.pumpAndSettle();

      final montoField = tester.widget<TextField>(find.byKey(const Key('checkoutMonto_0')));
      expect(montoField.controller!.text, '1.000');
      expect(montoField.readOnly, isTrue);

      await tester.tap(find.byKey(const Key('checkoutConfirmar')));
      await tester.pumpAndSettle();

      final resultado = resultadoObtenido[0]!;
      expect(resultado.pagos.single.medioPago, MedioPago.notaCredito);
      expect(resultado.pagos.single.notaCreditoClienteId, 'nota-1');
      expect(resultado.pagos.single.monto, 1000);
    });

    testWidgets('elegir Nota de Crédito sin elegir una Nota puntual deja Confirmar deshabilitado', (tester) async {
      fake.notasARetornar = [
        NotaCreditoClienteResumen(
          id: 'nota-1',
          folio: 'NC-20260813-001',
          montoTotal: 1000,
          estado: EstadoNotaCreditoCliente.disponible,
          fechaEmision: DateTime(2026, 8, 13),
          motivo: 'Devolución',
        ),
      ];
      await abrirDialogoConNotas(tester, total: 1000, cliente: _clienteCompleto);

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nota de Crédito').last);
      await tester.pumpAndSettle();

      final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
      expect(boton.onPressed, isNull);
    });
  });

  group('Anticipo como medio de pago', () {
    Future<void> abrirDialogoConAnticipos(
      WidgetTester tester, {
      required double total,
      List<AnticipoDisponibleParaPago> anticipos = const [],
    }) async {
      resultadoObtenido[0] = null;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultadoObtenido[0] = await showDialog<ResultadoCheckout>(
                  context: context,
                  builder: (_) => CheckoutDialog(
                    total: total,
                    formaPago: FormaPago.contado,
                    clienteSeleccionado: null,
                    anticiposDisponibles: anticipos,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('sin Anticipos disponibles, Anticipo no aparece como opción', (tester) async {
      await abrirDialogoConAnticipos(tester, total: 1000);

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();

      expect(find.text('Anticipo'), findsNothing);
    });

    testWidgets('con Anticipos disponibles, elegir uno fija el Monto a su valor íntegro', (tester) async {
      await abrirDialogoConAnticipos(
        tester,
        total: 1000,
        anticipos: const [AnticipoDisponibleParaPago(id: 'anticipo-1', monto: 1000, etiquetaMedioPagoOriginal: 'Efectivo')],
      );

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anticipo').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkoutAnticipo_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Efectivo · \$1.000').last);
      await tester.pumpAndSettle();

      final montoField = tester.widget<TextField>(find.byKey(const Key('checkoutMonto_0')));
      expect(montoField.controller!.text, '1.000');
      expect(montoField.readOnly, isTrue);

      await tester.tap(find.byKey(const Key('checkoutConfirmar')));
      await tester.pumpAndSettle();

      final resultado = resultadoObtenido[0]!;
      expect(resultado.pagos.single.medioPago, MedioPago.anticipo);
      expect(resultado.pagos.single.anticipoOrdenTrabajoId, 'anticipo-1');
      expect(resultado.pagos.single.monto, 1000);
    });

    testWidgets('elegir Anticipo sin elegir uno puntual deja Confirmar deshabilitado', (tester) async {
      await abrirDialogoConAnticipos(
        tester,
        total: 1000,
        anticipos: const [AnticipoDisponibleParaPago(id: 'anticipo-1', monto: 1000, etiquetaMedioPagoOriginal: 'Efectivo')],
      );

      await tester.tap(find.byKey(const Key('checkoutMedioPago_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anticipo').last);
      await tester.pumpAndSettle();

      final boton = tester.widget<FilledButton>(find.byKey(const Key('checkoutConfirmar')));
      expect(boton.onPressed, isNull);
    });
  });
}
