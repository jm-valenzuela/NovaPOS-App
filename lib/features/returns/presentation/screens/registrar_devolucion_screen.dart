import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../customers/domain/models/cliente_resumen.dart';
import '../../../sales/presentation/widgets/selector_cliente_dialog.dart';
import '../../domain/models/linea_devolucion_input.dart';
import '../../domain/models/venta_para_devolucion_detalle.dart';
import '../providers/returns_providers.dart';

/// Atención de Clientes: registrar la devolución (total o parcial) de una
/// Venta Confirmada (Boleta o Factura) — la Venta a devolver ya se eligió
/// antes de llegar acá (ver DevolucionVentaScreen). Elegir líneas/
/// cantidades, Motivo y Cliente (si la Venta original fue del Cliente
/// Genérico, exige elegir/crear uno real). Siempre queda como Nota de
/// Crédito Disponible: el reembolso en efectivo, si corresponde, se hace
/// después desde el POS (ver ElegirNotaCreditoDevolucionDialog, que sí
/// necesita una Sesión de Caja Abierta — algo que Atención de Clientes no
/// tiene por qué requerir).
class RegistrarDevolucionScreen extends ConsumerStatefulWidget {
  const RegistrarDevolucionScreen({super.key, required this.ventaId});

  final String ventaId;

  @override
  ConsumerState<RegistrarDevolucionScreen> createState() => _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends ConsumerState<RegistrarDevolucionScreen> {
  VentaParaDevolucionDetalle? _detalle;
  bool _cargandoDetalle = true;
  String? _errorDetalle;

  ClienteResumen? _clienteElegido;
  final Map<String, TextEditingController> _cantidadControllers = {};
  final _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    for (final controller in _cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _cargandoDetalle = true;
      _errorDetalle = null;
    });
    try {
      final detalle = await ref.read(returnsRepositoryProvider).obtenerVentaParaDevolucion(widget.ventaId);
      for (final controller in _cantidadControllers.values) {
        controller.dispose();
      }
      _cantidadControllers.clear();
      for (final linea in detalle.lineas) {
        _cantidadControllers[linea.varianteProductoId] = TextEditingController(text: '0');
      }
      setState(() {
        _detalle = detalle;
        _cargandoDetalle = false;
      });
    } catch (e) {
      setState(() {
        _cargandoDetalle = false;
        _errorDetalle = e.toString();
      });
    }
  }

  double _cantidad(String varianteProductoId) =>
      double.tryParse(_cantidadControllers[varianteProductoId]?.text.replaceAll(',', '.') ?? '') ?? 0;

  List<LineaVentaParaDevolucion> get _lineasAEnviar =>
      _detalle == null ? const [] : _detalle!.lineas.where((l) => _cantidad(l.varianteProductoId) > 0).toList();

  double get _montoADevolver => _lineasAEnviar.fold(0, (suma, linea) {
        final precioEfectivoUnitario = linea.subtotal / linea.cantidad;
        return suma + precioEfectivoUnitario * _cantidad(linea.varianteProductoId);
      });

  String? get _clienteIdEfectivo {
    if (_detalle == null) return null;
    return _detalle!.clienteEsGenerico ? _clienteElegido?.id : _detalle!.clienteId;
  }

  bool get _algunaCantidadExcedeElMaximo =>
      _detalle?.lineas.any((l) => _cantidad(l.varianteProductoId) > l.cantidadDevolvible) ?? false;

  bool get _puedeEnviar =>
      _detalle != null &&
      _clienteIdEfectivo != null &&
      _lineasAEnviar.isNotEmpty &&
      _motivoController.text.trim().isNotEmpty &&
      !_algunaCantidadExcedeElMaximo;

  Future<void> _elegirClienteReal() async {
    final cliente = await showDialog<ClienteResumen>(
      context: context,
      builder: (_) => const SelectorClienteDialog(permitirClienteGenerico: false),
    );
    if (cliente == null || !mounted) return;
    setState(() => _clienteElegido = cliente);
  }

  Future<void> _registrar() async {
    final detalle = _detalle;
    final clienteId = _clienteIdEfectivo;
    if (detalle == null || clienteId == null) return;

    final id = await ref.read(registrarDevolucionProvider.notifier).registrar(
          ventaOrigenId: detalle.ventaId,
          clienteId: clienteId,
          lineas: _lineasAEnviar
              .map((l) => LineaDevolucionInput(varianteProductoId: l.varianteProductoId, cantidad: _cantidad(l.varianteProductoId)))
              .toList(),
          motivo: _motivoController.text.trim(),
          reembolsarEnEfectivo: false,
          sesionCajaId: null,
        );
    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Devolución registrada — Nota de Crédito disponible para el Cliente.'),
      ));
      context.pop();
    } else {
      final error = ref.read(registrarDevolucionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo registrar la devolución: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devolución de productos')),
      body: _pasoDetalle(),
    );
  }

  Widget _pasoDetalle() {
    if (_cargandoDetalle) return const Center(child: CircularProgressIndicator());
    if (_errorDetalle != null) {
      return Center(child: Text('No se pudo cargar la Venta: $_errorDetalle'));
    }
    final detalle = _detalle!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Devolución de la Venta de ${detalle.clienteNombre}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (detalle.clienteEsGenerico) _avisoClienteGenerico(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final linea in detalle.lineas) _filaLinea(linea),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('devolucionMotivo'),
                    controller: _motivoController,
                    decoration: const InputDecoration(labelText: 'Motivo de la devolución'),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text('Monto a devolver: ${MonedaFormatter.formatear(_montoADevolver)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'Queda como Nota de Crédito Disponible para el Cliente — el reembolso en efectivo, si corresponde, '
                    'se hace después desde el menú de Caja del POS.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('devolucionConfirmar'),
              onPressed: _puedeEnviar ? _registrar : null,
              child: Text('Registrar devolución ${MonedaFormatter.formatear(_montoADevolver)} por Nota de Crédito'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoClienteGenerico() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _clienteElegido == null
                    ? 'Esta Venta fue del Cliente Genérico — la Nota de Crédito debe quedar a nombre de un Cliente real.'
                    : 'Nota de Crédito a nombre de: ${_clienteElegido!.nombre}',
              ),
            ),
            TextButton(
              key: const Key('devolucionElegirClienteReal'),
              onPressed: _elegirClienteReal,
              child: Text(_clienteElegido == null ? 'Elegir Cliente' : 'Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaLinea(LineaVentaParaDevolucion linea) {
    final controller = _cantidadControllers[linea.varianteProductoId]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(linea.nombreProducto, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${linea.sku} · comprado ${linea.cantidad} · ya devuelto ${linea.cantidadYaDevuelta}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              key: Key('devolucionCantidad_${linea.varianteProductoId}'),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(labelText: 'Cantidad', helperText: 'máx. ${linea.cantidadDevolvible}'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
