import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/proveedor.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';
import 'selector_proveedor_dialog.dart';

/// Registro de Factura Interna desde la pantalla propia (independiente de
/// Documentos Recibidos por Proveedor) — a diferencia de
/// RegistrarDocumentoRecibidoDialog, acá el Proveedor se elige con
/// SelectorProveedorDialog (buscar o crear rápido, sin pre-navegar a un
/// Proveedor existente) y nunca hay Orden de Compra, así que la Categoría
/// siempre es obligatoria. Suma el adjunto de respaldo (Foto o PDF).
class RegistrarFacturaInternaDialog extends ConsumerStatefulWidget {
  const RegistrarFacturaInternaDialog({super.key});

  @override
  ConsumerState<RegistrarFacturaInternaDialog> createState() => _RegistrarFacturaInternaDialogState();
}

class _RegistrarFacturaInternaDialogState extends ConsumerState<RegistrarFacturaInternaDialog> {
  final _folioController = TextEditingController();
  final _rutEmisorController = TextEditingController();
  final _montoController = TextEditingController();
  TipoDocumentoRecibido _tipo = TipoDocumentoRecibido.factura;
  FormaPago _formaPago = FormaPago.contado;
  DateTime _fechaEmision = DateTime.now();
  CategoriaDocumentoRecibido? _categoria;
  ProveedorResumen? _proveedor;
  PlatformFile? _respaldo;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _folioController.dispose();
    _rutEmisorController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _elegirProveedor() async {
    final elegido = await showDialog<ProveedorResumen>(context: context, builder: (_) => const SelectorProveedorDialog());
    if (elegido == null) return;
    setState(() {
      _proveedor = elegido;
      if (_rutEmisorController.text.trim().isEmpty) _rutEmisorController.text = elegido.rut;
    });
  }

  Future<void> _elegirRespaldo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() => _respaldo = resultado.files.first);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Factura Interna'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ListTile(
                key: const Key('facturaInternaProveedor'),
                contentPadding: EdgeInsets.zero,
                title: Text(_proveedor?.nombre ?? 'Elegir Proveedor'),
                subtitle: _proveedor != null ? Text(_proveedor!.rut) : null,
                trailing: const Icon(Icons.search),
                onTap: _elegirProveedor,
              ),
              const SizedBox(height: 8),
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
                key: const Key('facturaInternaFolio'),
                controller: _folioController,
                decoration: const InputDecoration(labelText: 'Folio'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('facturaInternaRutEmisor'),
                controller: _rutEmisorController,
                decoration: const InputDecoration(labelText: 'RUT emisor'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('facturaInternaMonto'),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<CategoriaDocumentoRecibido>(
                key: const Key('facturaInternaCategoria'),
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                hint: const Text('Elige una categoría'),
                items: CategoriaDocumentoRecibido.values.map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta))).toList(),
                onChanged: (valor) => setState(() => _categoria = valor),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('facturaInternaRespaldo'),
                contentPadding: EdgeInsets.zero,
                title: Text(_respaldo?.name ?? 'Adjuntar respaldo (Foto o PDF, opcional)'),
                trailing: const Icon(Icons.attach_file),
                onTap: _elegirRespaldo,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('facturaInternaGuardar'),
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
    if (_proveedor == null) {
      setState(() => _error = 'Elige el Proveedor.');
      return;
    }

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

    if (_categoria == null) {
      setState(() => _error = 'Elige una Categoría (Gasto, Insumo, Servicio, etc.).');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(facturasInternasProvider.notifier).registrar(
          proveedorId: _proveedor!.id,
          tipoDocumento: _tipo,
          folio: folio,
          rutEmisor: RutValidator.normalizarConGuion(rutEmisor),
          montoTotal: monto,
          formaPago: _formaPago,
          fechaEmision: _fechaEmision,
          categoria: _categoria!,
          respaldoBytes: _respaldo?.bytes,
          respaldoNombreArchivo: _respaldo?.name,
        );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(facturasInternasProvider).error ?? 'No se pudo registrar la Factura Interna.';
      });
    }
  }
}
