import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/customers/domain/models/cliente_resumen.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/widgets/checkout_dialog.dart';

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
  Future<void> abrirDialogo(
    WidgetTester tester, {
    required double total,
    required FormaPago formaPago,
    ClienteResumen? cliente,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<ResultadoCheckout>(
            context: context,
            builder: (_) => CheckoutDialog(total: total, formaPago: formaPago, clienteSeleccionado: cliente),
          ),
          child: const Text('Abrir'),
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
}
