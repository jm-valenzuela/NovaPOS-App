import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';

/// Registra la Boleta/Factura real que emitió el Proveedor — OrdenCompraId
/// queda fuera de este formulario a propósito (no toda compra pasa por una
/// Orden formal, ver DocumentoRecibido.cs); si el monto difiere en más de
/// $1.000 del negociado en una Orden referenciada, el backend genera una
/// Discrepancia sola, sin que el usuario tenga que hacer nada acá.
class RegistrarDocumentoRecibidoDialog extends ConsumerStatefulWidget {
  const RegistrarDocumentoRecibidoDialog({super.key, required this.proveedorId, this.rutProveedor});

  final String proveedorId;
  final String? rutProveedor;

  @override
  ConsumerState<RegistrarDocumentoRecibidoDialog> createState() => _RegistrarDocumentoRecibidoDialogState();
}

class _RegistrarDocumentoRecibidoDialogState extends ConsumerState<RegistrarDocumentoRecibidoDialog> {
  late final _folioController = TextEditingController();
  late final _rutEmisorController = TextEditingController(text: widget.rutProveedor ?? '');
  late final _montoController = TextEditingController();
  TipoDocumentoRecibido _tipo = TipoDocumentoRecibido.factura;
  FormaPago _formaPago = FormaPago.contado;
  DateTime _fechaEmision = DateTime.now();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _folioController.dispose();
    _rutEmisorController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Documento Recibido'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              SegmentedButton<TipoDocumentoRecibido>(
                segments: const [
                  ButtonSegment(value: TipoDocumentoRecibido.boleta, label: Text('Boleta')),
                  ButtonSegment(value: TipoDocumentoRecibido.factura, label: Text('Factura')),
                ],
                selected: {_tipo},
                onSelectionChanged: (seleccion) => setState(() => _tipo = seleccion.first),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('documentoFolio'),
                controller: _folioController,
                decoration: const InputDecoration(labelText: 'Folio'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('documentoRutEmisor'),
                controller: _rutEmisorController,
                decoration: const InputDecoration(labelText: 'RUT emisor'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('documentoMonto'),
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto total'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              SegmentedButton<FormaPago>(
                segments: const [
                  ButtonSegment(value: FormaPago.contado, label: Text('Contado')),
                  ButtonSegment(value: FormaPago.credito, label: Text('Crédito')),
                ],
                selected: {_formaPago},
                onSelectionChanged: (seleccion) => setState(() => _formaPago = seleccion.first),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de emisión'),
                subtitle: Text(_fechaEmision.toLocal().toString().split(' ').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: _elegirFecha,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('documentoGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Registrar'),
        ),
      ],
    );
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaEmision,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fechaEmision = elegida);
  }

  Future<void> _guardar() async {
    final folio = int.tryParse(_folioController.text.trim());
    if (folio == null || folio <= 0) {
      setState(() => _error = 'El folio debe ser mayor a cero.');
      return;
    }

    final rutEmisor = _rutEmisorController.text.trim();
    if (!RutValidator.esValido(rutEmisor)) {
      setState(() => _error = 'El RUT del emisor no es válido.');
      return;
    }

    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _error = 'El monto total debe ser mayor a cero.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(documentosRecibidosProvider(widget.proveedorId).notifier).registrar(
          tipoDocumento: _tipo,
          folio: folio,
          rutEmisor: RutValidator.normalizarConGuion(rutEmisor),
          montoTotal: monto,
          formaPago: _formaPago,
          fechaEmision: _fechaEmision,
        );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(documentosRecibidosProvider(widget.proveedorId)).error ?? 'No se pudo registrar el documento.';
      });
    }
  }
}
