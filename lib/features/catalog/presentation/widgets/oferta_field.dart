import 'package:flutter/material.dart';

/// Resultado resuelto del selector — mismos 3 campos que
/// VarianteProducto.PrecioOferta/OfertaDesde/OfertaHasta en el backend.
/// Los 3 null = sin oferta.
class OfertaValor {
  const OfertaValor({this.precioOferta, this.ofertaDesde, this.ofertaHasta});

  final double? precioOferta;
  final DateTime? ofertaDesde;
  final DateTime? ofertaHasta;
}

/// Precio de oferta vigente solo dentro de un rango de fechas — mutuamente
/// excluyente con el descuento por volumen y la promoción por grupo (ver
/// VarianteProducto.ValidarPromocionesNoSeSuperponen en el backend), la
/// pantalla que use este widget debe validar esa exclusión mutua antes de
/// guardar. Usado en CatalogFormScreen y EditarVarianteDialog.
class OfertaField extends StatefulWidget {
  const OfertaField({
    super.key,
    this.precioOfertaInicial,
    this.ofertaDesdeInicial,
    this.ofertaHastaInicial,
    required this.onChanged,
  });

  final double? precioOfertaInicial;
  final DateTime? ofertaDesdeInicial;
  final DateTime? ofertaHastaInicial;
  final ValueChanged<OfertaValor> onChanged;

  @override
  State<OfertaField> createState() => _OfertaFieldState();
}

class _OfertaFieldState extends State<OfertaField> {
  late final _precioController = TextEditingController(text: widget.precioOfertaInicial?.toString() ?? '');
  late DateTime? _ofertaDesde = widget.ofertaDesdeInicial;
  late DateTime? _ofertaHasta = widget.ofertaHastaInicial;

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  void _emitir() {
    widget.onChanged(OfertaValor(
      precioOferta: double.tryParse(_precioController.text.replaceAll(',', '.')),
      ofertaDesde: _ofertaDesde,
      ofertaHasta: _ofertaHasta,
    ));
  }

  Future<void> _elegirDesde() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _ofertaDesde ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (elegida == null) return;
    setState(() => _ofertaDesde = elegida);
    _emitir();
  }

  Future<void> _elegirHasta() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _ofertaHasta ?? _ofertaDesde ?? DateTime.now(),
      firstDate: _ofertaDesde ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (elegida == null) return;
    setState(() => _ofertaHasta = elegida);
    _emitir();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('ofertaPrecio'),
          controller: _precioController,
          decoration: const InputDecoration(labelText: 'Precio de oferta'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _emitir(),
        ),
        const SizedBox(height: 12),
        ListTile(
          key: const Key('ofertaDesde'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Vigente desde'),
          subtitle: Text(_formatearFecha(_ofertaDesde)),
          trailing: const Icon(Icons.calendar_today),
          onTap: _elegirDesde,
        ),
        ListTile(
          key: const Key('ofertaHasta'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Vigente hasta'),
          subtitle: Text(_formatearFecha(_ofertaHasta)),
          trailing: const Icon(Icons.calendar_today),
          onTap: _elegirHasta,
        ),
      ],
    );
  }
}

String _formatearFecha(DateTime? fecha) => fecha == null ? 'Elegir fecha' : fecha.toLocal().toString().split(' ').first;
