import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../domain/models/pago_input.dart';
import '../../domain/models/venta_enums.dart';

/// Resultado de CheckoutDialog — pagos viene vacío si la Venta es a Crédito.
class ResultadoCheckout {
  const ResultadoCheckout({required this.tipoDocumento, required this.pagos});

  final TipoDocumento tipoDocumento;
  final List<PagoInput> pagos;
}

/// Se muestra al tocar "Cobrar" en el POS — el Cajero elige Boleta o
/// Factura (ya no se infiere automático según el RUT del Cliente, ver
/// Venta.Confirmar en el backend) y, si la Venta es al Contado, cómo se
/// paga (soporta pago mixto: varias líneas que deben sumar exacto el
/// Total). Si es a Crédito, no se pide medio de pago acá — el pago ocurre
/// después, vía Abonos en Cuentas por Cobrar.
class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({
    super.key,
    required this.total,
    required this.formaPago,
    required this.clienteSeleccionado,
  });

  final double total;
  final FormaPago formaPago;
  final ClienteResumen? clienteSeleccionado;

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _PagoEnEdicion {
  _PagoEnEdicion({required this.medioPago}) : controller = TextEditingController();

  MedioPago medioPago;
  final TextEditingController controller;

  double get monto => double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  TipoDocumento _tipoDocumento = TipoDocumento.boleta;
  final List<_PagoEnEdicion> _pagos = [_PagoEnEdicion(medioPago: MedioPago.efectivo)];
  String? _error;

  bool get _esContado => widget.formaPago == FormaPago.contado;

  /// Mismo criterio que Cliente.TieneDatosCompletosParaFactura() en el
  /// backend — evita que el Cajero elija Factura para un Cliente que el
  /// backend va a rechazar de todos modos (o para el Cliente Genérico,
  /// que no tiene RUT propio).
  bool get _clientePuedeFacturar {
    final cliente = widget.clienteSeleccionado;
    if (cliente == null) return false;
    final rut = cliente.rut;
    if (rut == null || rut.trim().isEmpty) return false;
    if (cliente.giro == null || cliente.giro!.trim().isEmpty) return false;
    if (cliente.direccion == null || cliente.direccion!.trim().isEmpty) return false;
    if (cliente.comuna == null || cliente.comuna!.trim().isEmpty) return false;
    return true;
  }

  static const _epsilon = 0.005;

  double get _montoNoEfectivo =>
      _pagos.where((p) => p.medioPago != MedioPago.efectivo).fold(0, (suma, p) => suma + p.monto);

  double get _montoEfectivo =>
      _pagos.where((p) => p.medioPago == MedioPago.efectivo).fold(0, (suma, p) => suma + p.monto);

  /// Lo que el Efectivo todavía debe cubrir después de restar Tarjeta/otros
  /// medios — puede ser negativo si esos medios ya superan el Total (ver
  /// _excedeSinEfectivo).
  double get _restanteParaEfectivo => widget.total - _montoNoEfectivo;

  /// Tarjeta (u otro medio sin vuelto) no puede superar el Total por sí
  /// sola — a diferencia del Efectivo, no hay "vuelto" en una tarjeta.
  bool get _excedeSinEfectivo => _montoNoEfectivo > widget.total + _epsilon;

  bool get _pagosCuadran => !_excedeSinEfectivo && _montoEfectivo >= _restanteParaEfectivo - _epsilon;

  /// Solo el Efectivo entregado de más se devuelve como vuelto — si el
  /// Cajero recibió $10.000 en efectivo y solo hacían falta $8.982, el
  /// vuelto son $1.018 (no se registra como parte del pago, ver
  /// _pagosParaEnviar).
  double get _vuelto {
    if (_excedeSinEfectivo || !_pagosCuadran) return 0;
    final exceso = _montoEfectivo - _restanteParaEfectivo;
    return exceso > _epsilon ? exceso : 0;
  }

  String get _mensajePagos {
    if (_excedeSinEfectivo) return 'El monto en medios distintos a Efectivo no puede superar el Total.';
    if (!_pagosCuadran) return 'Falta ${MonedaFormatter.formatear(_restanteParaEfectivo - _montoEfectivo)} por cubrir.';
    if (_vuelto > 0) return 'Vuelto: ${MonedaFormatter.formatear(_vuelto)}';
    return 'Los pagos cuadran con el Total.';
  }

  @override
  void dispose() {
    for (final pago in _pagos) {
      pago.controller.dispose();
    }
    super.dispose();
  }

  void _agregarPago() {
    setState(() => _pagos.add(_PagoEnEdicion(medioPago: MedioPago.efectivo)));
  }

  void _quitarPago(int indice) {
    if (_pagos.length <= 1) return;
    setState(() {
      _pagos[indice].controller.dispose();
      _pagos.removeAt(indice);
    });
  }

  void _confirmar() {
    if (_esContado && !_pagosCuadran) {
      setState(() => _error = _excedeSinEfectivo
          ? 'El monto en medios distintos a Efectivo no puede superar el Total.'
          : 'Falta cubrir el Total.');
      return;
    }

    Navigator.of(context).pop(ResultadoCheckout(tipoDocumento: _tipoDocumento, pagos: _pagosParaEnviar()));
  }

  /// El backend exige que la suma de los pagos coincida EXACTO con el
  /// Total (ver Venta.Confirmar) — el vuelto no es parte del pago, así
  /// que se descuenta acá del monto de Efectivo antes de enviar (nunca
  /// del monto tendido que el Cajero tipeó, ese es solo para calcular el
  /// vuelto en pantalla). Se descuenta desde la última línea en Efectivo
  /// hacia la primera, por si hubiera más de una.
  List<PagoInput> _pagosParaEnviar() {
    if (!_esContado) return const [];

    var vueltoRestante = _vuelto;
    final resultado = <PagoInput>[];
    for (var i = _pagos.length - 1; i >= 0; i--) {
      final pago = _pagos[i];
      var monto = pago.monto;
      if (pago.medioPago == MedioPago.efectivo && vueltoRestante > 0) {
        final descuento = monto < vueltoRestante ? monto : vueltoRestante;
        monto -= descuento;
        vueltoRestante -= descuento;
      }
      resultado.insert(0, PagoInput(medioPago: pago.medioPago, monto: monto));
    }
    return resultado.where((p) => p.monto > _epsilon).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar cobro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total a cobrar: ${MonedaFormatter.formatear(widget.total)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Tipo de documento', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TipoDocumento>(
              key: const Key('checkoutTipoDocumento'),
              segments: [
                const ButtonSegment(value: TipoDocumento.boleta, label: Text('Boleta')),
                ButtonSegment(
                  value: TipoDocumento.factura,
                  label: const Text('Factura'),
                  enabled: _clientePuedeFacturar,
                ),
              ],
              selected: {_tipoDocumento},
              onSelectionChanged: (seleccion) => setState(() => _tipoDocumento = seleccion.first),
            ),
            if (!_clientePuedeFacturar) ...[
              const SizedBox(height: 4),
              Text(
                'Factura requiere un Cliente con RUT, Giro, Dirección y Comuna completos.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_esContado) ...[
              const SizedBox(height: 20),
              Text('Medio de pago', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (var i = 0; i < _pagos.length; i++) _filaPago(i),
              TextButton.icon(
                key: const Key('checkoutAgregarPago'),
                onPressed: _agregarPago,
                icon: const Icon(Icons.add),
                label: const Text('Agregar medio de pago'),
              ),
              const SizedBox(height: 4),
              Text(
                _mensajePagos,
                style: TextStyle(color: _pagosCuadran ? Colors.green : Theme.of(context).colorScheme.error),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('checkoutCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('checkoutConfirmar'),
          onPressed: (_esContado && !_pagosCuadran) ? null : _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _filaPago(int indice) {
    final pago = _pagos[indice];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<MedioPago>(
              key: Key('checkoutMedioPago_$indice'),
              value: pago.medioPago,
              items: MedioPago.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.etiqueta)))
                  .toList(),
              onChanged: (valor) => setState(() => pago.medioPago = valor ?? pago.medioPago),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('checkoutMonto_$indice'),
              controller: pago.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Monto'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_pagos.length > 1)
            IconButton(
              key: Key('checkoutQuitarPago_$indice'),
              onPressed: () => _quitarPago(indice),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
