import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/orden_compra.dart';
import '../../domain/models/proveedor.dart';
import '../../domain/models/purchasing_enums.dart';
import '../providers/purchasing_providers.dart';
import 'selector_proveedor_dialog.dart';

/// Registra un Documento Recibido — la Boleta/Factura real de un Proveedor,
/// ligada a una Orden de Compra (mercadería) o no (entonces es una "Factura
/// Interna" y debe clasificarse por Categoría — ver DocumentoRecibido en el
/// backend, que rechaza tener ambas a la vez). El Proveedor se elige con
/// SelectorProveedorDialog (buscar o crear rápido) — a pedido explícito del
/// usuario, esta pantalla ya no depende de estar parado en un Proveedor
/// puntual. Suma el adjunto de respaldo (Foto o PDF), mismo criterio que
/// RegistrarFacturaInternaDialog.
class RegistrarDocumentoRecibidoDialog extends ConsumerStatefulWidget {
  const RegistrarDocumentoRecibidoDialog({super.key});

  @override
  ConsumerState<RegistrarDocumentoRecibidoDialog> createState() => _RegistrarDocumentoRecibidoDialogState();
}

class _RegistrarDocumentoRecibidoDialogState extends ConsumerState<RegistrarDocumentoRecibidoDialog> {
  final _folioController = TextEditingController();
  final _rutEmisorController = TextEditingController();
  final _montoController = TextEditingController();
  TipoDocumentoRecibido _tipo = TipoDocumentoRecibido.factura;
  FormaPago _formaPago = FormaPago.contado;
  DateTime _fechaEmision = DateTime.now();
  String? _ordenCompraId;
  CategoriaDocumentoRecibido? _categoria;
  ProveedorResumen? _proveedor;
  PlatformFile? _respaldo;
  bool _guardando = false;
  String? _error;

  Future<List<OrdenCompraResumenListado>>? _ordenesFuturo;

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
      _ordenCompraId = null;
      if (_rutEmisorController.text.trim().isEmpty) _rutEmisorController.text = elegido.rut;
      _ordenesFuturo = ref.read(purchasingRepositoryProvider).listarOrdenesCompra(proveedorId: elegido.id).then(
            (ordenes) => ordenes
                .where((o) => o.estado == EstadoOrdenCompra.recibida || o.estado == EstadoOrdenCompra.parcialmenteRecibida)
                .toList(),
          );
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
      title: const Text('Registrar Documento Recibido'),
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
                key: const Key('documentoProveedor'),
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
              if (_proveedor != null) ...[
                const SizedBox(height: 12),
                FutureBuilder<List<OrdenCompraResumenListado>>(
                  future: _ordenesFuturo,
                  builder: (context, snapshot) {
                    final ordenes = snapshot.data ?? const <OrdenCompraResumenListado>[];
                    return DropdownButtonFormField<String?>(
                      key: const Key('documentoOrdenCompra'),
                      value: _ordenCompraId,
                      decoration: const InputDecoration(labelText: 'Orden de Compra (opcional)'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Ninguna — Factura Interna')),
                        ...ordenes.map((o) => DropdownMenuItem<String?>(
                              value: o.id,
                              child: Text('Orden #${o.id.substring(0, 8)} · ${o.estado.etiqueta}'),
                            )),
                      ],
                      onChanged: (valor) => setState(() {
                        _ordenCompraId = valor;
                        if (valor != null) _categoria = null;
                      }),
                    );
                  },
                ),
                if (_ordenCompraId == null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CategoriaDocumentoRecibido>(
                    key: const Key('documentoCategoria'),
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    hint: const Text('Elige una categoría'),
                    items: CategoriaDocumentoRecibido.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta)))
                        .toList(),
                    onChanged: (valor) => setState(() => _categoria = valor),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              ListTile(
                key: const Key('documentoRespaldo'),
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

    if (_ordenCompraId == null && _categoria == null) {
      setState(() => _error = 'Sin Orden de Compra, elige una Categoría (Gasto, Insumo, Servicio, etc.).');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(documentosRecibidosProvider.notifier).registrar(
          proveedorId: _proveedor!.id,
          ordenCompraId: _ordenCompraId,
          tipoDocumento: _tipo,
          folio: folio,
          rutEmisor: RutValidator.normalizarConGuion(rutEmisor),
          montoTotal: monto,
          formaPago: _formaPago,
          fechaEmision: _fechaEmision,
          categoria: _ordenCompraId == null ? _categoria : null,
          respaldoBytes: _respaldo?.bytes,
          respaldoNombreArchivo: _respaldo?.name,
        );

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(documentosRecibidosProvider).error ?? 'No se pudo registrar el documento.';
      });
    }
  }
}
