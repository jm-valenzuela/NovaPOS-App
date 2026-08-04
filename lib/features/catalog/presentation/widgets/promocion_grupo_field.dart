import 'package:flutter/material.dart';

/// Resultado resuelto del selector — mismos 2 campos que
/// VarianteProducto.CantidadPorGrupoPromocion/PorcentajeDescuentoUnidadPromocion
/// en el backend. Ambos null = sin promoción.
class PromocionGrupoValor {
  const PromocionGrupoValor({this.cantidadPorGrupo, this.porcentajeDescuentoUnidad});

  final int? cantidadPorGrupo;
  final double? porcentajeDescuentoUnidad;
}

enum _TipoPromocion { ninguna, dosXUno, tresXDos, seisXCinco, segundoDescuento, personalizada }

/// Dropdown con presets (2x1, 3x2, 6x5, "segundo producto con % dto.") más
/// una opción "Personalizada" con los 2 campos libres — un único mecanismo
/// parametrizado (cantidad por grupo + % de descuento en la última unidad)
/// cubre cualquier promoción NxM, los presets solo evitan tener que conocer
/// la fórmula para los casos más comunes. Usado en CatalogFormScreen y
/// EditarVarianteDialog.
class PromocionGrupoField extends StatefulWidget {
  const PromocionGrupoField({
    super.key,
    this.cantidadPorGrupoInicial,
    this.porcentajeDescuentoUnidadInicial,
    required this.onChanged,
  });

  final int? cantidadPorGrupoInicial;
  final double? porcentajeDescuentoUnidadInicial;
  final ValueChanged<PromocionGrupoValor> onChanged;

  @override
  State<PromocionGrupoField> createState() => _PromocionGrupoFieldState();
}

class _PromocionGrupoFieldState extends State<PromocionGrupoField> {
  late _TipoPromocion _tipo = _inferirTipo(widget.cantidadPorGrupoInicial, widget.porcentajeDescuentoUnidadInicial);

  late final _porcentajeSegundoController = TextEditingController(
    text: _tipo == _TipoPromocion.segundoDescuento ? widget.porcentajeDescuentoUnidadInicial?.toString() ?? '' : '',
  );
  late final _cantidadPersonalizadaController = TextEditingController(
    text: _tipo == _TipoPromocion.personalizada ? widget.cantidadPorGrupoInicial?.toString() ?? '' : '',
  );
  late final _porcentajePersonalizadaController = TextEditingController(
    text: _tipo == _TipoPromocion.personalizada ? widget.porcentajeDescuentoUnidadInicial?.toString() ?? '' : '',
  );

  static _TipoPromocion _inferirTipo(int? cantidad, double? porcentaje) {
    if (cantidad == null || porcentaje == null) return _TipoPromocion.ninguna;
    if (cantidad == 2 && porcentaje == 100) return _TipoPromocion.dosXUno;
    if (cantidad == 3 && porcentaje == 100) return _TipoPromocion.tresXDos;
    if (cantidad == 6 && porcentaje == 100) return _TipoPromocion.seisXCinco;
    if (cantidad == 2) return _TipoPromocion.segundoDescuento;
    return _TipoPromocion.personalizada;
  }

  @override
  void dispose() {
    _porcentajeSegundoController.dispose();
    _cantidadPersonalizadaController.dispose();
    _porcentajePersonalizadaController.dispose();
    super.dispose();
  }

  void _emitir() {
    switch (_tipo) {
      case _TipoPromocion.ninguna:
        widget.onChanged(const PromocionGrupoValor());
      case _TipoPromocion.dosXUno:
        widget.onChanged(const PromocionGrupoValor(cantidadPorGrupo: 2, porcentajeDescuentoUnidad: 100));
      case _TipoPromocion.tresXDos:
        widget.onChanged(const PromocionGrupoValor(cantidadPorGrupo: 3, porcentajeDescuentoUnidad: 100));
      case _TipoPromocion.seisXCinco:
        widget.onChanged(const PromocionGrupoValor(cantidadPorGrupo: 6, porcentajeDescuentoUnidad: 100));
      case _TipoPromocion.segundoDescuento:
        widget.onChanged(PromocionGrupoValor(
          cantidadPorGrupo: 2,
          porcentajeDescuentoUnidad: double.tryParse(_porcentajeSegundoController.text.replaceAll(',', '.')),
        ));
      case _TipoPromocion.personalizada:
        widget.onChanged(PromocionGrupoValor(
          cantidadPorGrupo: int.tryParse(_cantidadPersonalizadaController.text),
          porcentajeDescuentoUnidad: double.tryParse(_porcentajePersonalizadaController.text.replaceAll(',', '.')),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<_TipoPromocion>(
          key: const Key('promocionGrupoTipo'),
          decoration: const InputDecoration(labelText: 'Tipo de promoción'),
          value: _tipo,
          items: const [
            DropdownMenuItem(value: _TipoPromocion.ninguna, child: Text('Sin promoción')),
            DropdownMenuItem(value: _TipoPromocion.dosXUno, child: Text('2x1')),
            DropdownMenuItem(value: _TipoPromocion.tresXDos, child: Text('3x2')),
            DropdownMenuItem(value: _TipoPromocion.seisXCinco, child: Text('6x5')),
            DropdownMenuItem(value: _TipoPromocion.segundoDescuento, child: Text('Segundo producto con % dto.')),
            DropdownMenuItem(value: _TipoPromocion.personalizada, child: Text('Personalizada')),
          ],
          onChanged: (tipo) {
            setState(() => _tipo = tipo ?? _TipoPromocion.ninguna);
            _emitir();
          },
        ),
        if (_tipo == _TipoPromocion.segundoDescuento) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('promocionSegundoPorcentaje'),
            controller: _porcentajeSegundoController,
            decoration: const InputDecoration(labelText: '% de descuento en el segundo'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emitir(),
          ),
        ],
        if (_tipo == _TipoPromocion.personalizada) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('promocionPersonalizadaCantidad'),
            controller: _cantidadPersonalizadaController,
            decoration: const InputDecoration(labelText: 'Cada cuántas unidades'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _emitir(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('promocionPersonalizadaPorcentaje'),
            controller: _porcentajePersonalizadaController,
            decoration: const InputDecoration(labelText: '% dto. en la última unidad'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emitir(),
          ),
        ],
      ],
    );
  }
}
