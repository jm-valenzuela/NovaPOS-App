import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formateador_miles.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../returns/domain/models/nota_credito_cliente_resumen.dart';
import '../../../returns/presentation/providers/returns_providers.dart';
import '../../domain/models/pago_input.dart';
import '../../domain/models/venta_enums.dart';

/// Resultado de CheckoutDialog — pagos viene vacío si la Venta es a Crédito.
/// vuelto es 0 salvo que la Venta sea al Contado en Efectivo por sobre el
/// Total (ver _vuelto) — se propaga para mostrarlo en el resumen final de
/// PosScreen, ya que el pago enviado al backend nunca lo incluye.
class ResultadoCheckout {
  const ResultadoCheckout({required this.tipoDocumento, required this.pagos, this.vuelto = 0});

  final TipoDocumento tipoDocumento;
  final List<PagoInput> pagos;
  final double vuelto;
}

/// Se muestra al tocar "Cobrar" en el POS — el Cajero elige Boleta o
/// Factura (ya no se infiere automático según el RUT del Cliente, ver
/// Venta.Confirmar en el backend) y, si la Venta es al Contado, cómo se
/// paga (soporta pago mixto: varias líneas que deben sumar exacto el
/// Total). Si es a Crédito, no se pide medio de pago acá — el pago ocurre
/// después, vía Abonos en Cuentas por Cobrar.
class CheckoutDialog extends ConsumerStatefulWidget {
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
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _PagoEnEdicion {
  _PagoEnEdicion({required this.medioPago}) : controller = TextEditingController();

  MedioPago medioPago;
  final TextEditingController controller;

  /// Solo cuando medioPago es notaCredito — qué NotaCreditoCliente Disponible se eligió.
  String? notaCreditoId;

  double get monto => FormateadorMiles.desformatear(controller.text);
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  TipoDocumento _tipoDocumento = TipoDocumento.boleta;
  final List<_PagoEnEdicion> _pagos = [_PagoEnEdicion(medioPago: MedioPago.efectivo)];
  String? _error;

  bool get _esContado => widget.formaPago == FormaPago.contado;

  /// La Nota de Crédito es nominativa — solo se ofrece como medio de pago
  /// si hay un Cliente real elegido (no el Genérico, ver
  /// Cliente.RutClienteGenerico en el backend; acá "Genérico" se
  /// representa como clienteSeleccionado == null).
  bool get _puedeUsarNotaCredito => widget.clienteSeleccionado != null;

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

  /// Todo pago con Nota de Crédito debe tener una Nota elegida — un
  /// medioPago sin notaCreditoId no se puede enviar.
  bool get _faltaElegirAlgunaNota =>
      _pagos.any((p) => p.medioPago == MedioPago.notaCredito && p.notaCreditoId == null);

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
    if (_faltaElegirAlgunaNota) return 'Elige qué Nota de Crédito se usa en cada línea de pago con ese medio.';
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
    if (_esContado && (!_pagosCuadran || _faltaElegirAlgunaNota)) {
      setState(() => _error = _faltaElegirAlgunaNota
          ? 'Elige qué Nota de Crédito se usa en cada línea de pago con ese medio.'
          : _excedeSinEfectivo
              ? 'El monto en medios distintos a Efectivo no puede superar el Total.'
              : 'Falta cubrir el Total.');
      return;
    }

    Navigator.of(context)
        .pop(ResultadoCheckout(tipoDocumento: _tipoDocumento, pagos: _pagosParaEnviar(), vuelto: _esContado ? _vuelto : 0));
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
      resultado.insert(0, PagoInput(medioPago: pago.medioPago, monto: monto, notaCreditoClienteId: pago.notaCreditoId));
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
            if (_esContado && _vuelto > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Vuelto: ${MonedaFormatter.formatear(_vuelto)}',
                key: const Key('checkoutVueltoArriba'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
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
                style: TextStyle(color: (_pagosCuadran && !_faltaElegirAlgunaNota) ? Colors.green : Theme.of(context).colorScheme.error),
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
          onPressed: (_esContado && (!_pagosCuadran || _faltaElegirAlgunaNota)) ? null : _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _filaPago(int indice) {
    final pago = _pagos[indice];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<MedioPago>(
                  key: Key('checkoutMedioPago_$indice'),
                  value: pago.medioPago,
                  items: MedioPago.values
                      .where((m) => m != MedioPago.notaCredito || _puedeUsarNotaCredito)
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.etiqueta)))
                      .toList(),
                  onChanged: (valor) => setState(() {
                    pago.medioPago = valor ?? pago.medioPago;
                    pago.notaCreditoId = null;
                    pago.controller.clear();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  key: Key('checkoutMonto_$indice'),
                  controller: pago.controller,
                  readOnly: pago.medioPago == MedioPago.notaCredito,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FormateadorMiles()],
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
          if (pago.medioPago == MedioPago.notaCredito) _selectorNotaCredito(indice, pago),
        ],
      ),
    );
  }

  Widget _selectorNotaCredito(int indice, _PagoEnEdicion pago) {
    final clienteId = widget.clienteSeleccionado!.id;
    final notasAsync = ref.watch(notasDisponiblesProvider(clienteId));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: notasAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Text('No se pudieron cargar las Notas de Crédito: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        data: (notas) {
          if (notas.isEmpty) {
            return const Text('Este Cliente no tiene Notas de Crédito Disponibles.', style: TextStyle(color: Colors.grey));
          }
          return DropdownButtonFormField<NotaCreditoClienteResumen>(
            key: Key('checkoutNotaCredito_$indice'),
            value: notas.where((n) => n.id == pago.notaCreditoId).firstOrNull,
            decoration: const InputDecoration(labelText: 'Nota de Crédito', isDense: true),
            items: notas
                .map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('${n.folio} · ${MonedaFormatter.formatear(n.montoTotal)}'),
                    ))
                .toList(),
            onChanged: (nota) => setState(() {
              pago.notaCreditoId = nota?.id;
              pago.controller.text = nota == null ? '' : FormateadorMiles.formatear(nota.montoTotal);
            }),
          );
        },
      ),
    );
  }
}
