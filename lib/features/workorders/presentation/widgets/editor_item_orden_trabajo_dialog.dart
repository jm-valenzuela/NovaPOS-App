import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formateador_miles.dart';
import '../../../catalog/domain/models/producto_vendible.dart';
import '../../../sales/domain/models/linea_carrito.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show busquedaProductosProvider;
import '../../../sales/presentation/theme/pos_colors.dart';
import '../../../sales/presentation/widgets/cantidad_pesable_dialog.dart';
import '../../../sales/presentation/widgets/carrito_linea_tile.dart';
import '../../../sales/presentation/widgets/producto_resultado_tile.dart';
import '../../domain/models/orden_trabajo.dart';
import '../providers/workorders_providers.dart';

/// Línea de Trabajo en edición — a diferencia del Producto (que reusa
/// LineaCarrito para reusar también CarritoLineaTile), acá el monto lo
/// pone a mano quien cotiza, sin ningún precio de Catálogo detrás.
class _LineaTrabajoEnEdicion {
  _LineaTrabajoEnEdicion({String descripcion = ''})
      : descripcionController = TextEditingController(text: descripcion),
        montoController = TextEditingController();

  final TextEditingController descripcionController;
  final TextEditingController montoController;

  void dispose() {
    descripcionController.dispose();
    montoController.dispose();
  }
}

/// Un único diálogo cubre los dos únicos momentos en que se arma la lista
/// de líneas de un Ítem: agregar un Ítem nuevo (itemIdACotizar null — si
/// se deja sin líneas, el Ítem nace Pendiente de evaluación) y cerrar la
/// evaluación de un Ítem ya existente (itemIdACotizar no null — acá sí
/// exige al menos una línea, ver ItemOrdenTrabajo.Cotizar). Reusa el mismo
/// buscador de Catálogo con tarjetas de oferta/promoción y el mismo
/// CarritoLineaTile con stepper que ya usa el POS — mismo lenguaje visual,
/// sin reinventar la lógica de precio.
class EditorItemOrdenTrabajoDialog extends ConsumerStatefulWidget {
  const EditorItemOrdenTrabajoDialog({
    super.key,
    required this.ordenTrabajoId,
    this.itemIdACotizar,
    this.descripcionExistente,
  });

  final String ordenTrabajoId;

  /// null: se está agregando un Ítem nuevo. No-null: se está cotizando este Ítem ya existente.
  final String? itemIdACotizar;
  final String? descripcionExistente;

  @override
  ConsumerState<EditorItemOrdenTrabajoDialog> createState() => _EditorItemOrdenTrabajoDialogState();
}

class _EditorItemOrdenTrabajoDialogState extends ConsumerState<EditorItemOrdenTrabajoDialog> {
  final _descripcionController = TextEditingController();
  final _lineasTrabajo = <_LineaTrabajoEnEdicion>[];
  final _lineasProducto = <LineaCarrito>[];
  bool _agregandoProducto = false;
  bool _guardando = false;
  String? _error;
  final _busquedaController = TextEditingController();

  bool get _esCotizarExistente => widget.itemIdACotizar != null;

  @override
  void dispose() {
    _descripcionController.dispose();
    for (final linea in _lineasTrabajo) {
      linea.dispose();
    }
    _busquedaController.dispose();
    super.dispose();
  }

  void _agregarLineaTrabajo() => setState(() => _lineasTrabajo.add(_LineaTrabajoEnEdicion()));

  void _quitarLineaTrabajo(int indice) {
    setState(() {
      _lineasTrabajo[indice].dispose();
      _lineasTrabajo.removeAt(indice);
    });
  }

  void _agregarProducto(ProductoVendible producto) {
    setState(() {
      _lineasProducto.add(LineaCarrito(producto: producto, cantidad: 1));
      _agregandoProducto = false;
      _busquedaController.clear();
    });
  }

  void _quitarLineaProducto(int indice) => setState(() => _lineasProducto.removeAt(indice));

  void _cambiarCantidadProducto(int indice, double nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _quitarLineaProducto(indice);
      return;
    }
    setState(() => _lineasProducto[indice] = _lineasProducto[indice].copyWith(cantidad: nuevaCantidad));
  }

  Future<void> _editarCantidadProducto(int indice) async {
    final linea = _lineasProducto[indice];
    final cantidad = await showDialog<double>(
      context: context,
      builder: (_) => CantidadPesableDialog(producto: linea.producto, cantidadInicial: linea.cantidad),
    );
    if (cantidad == null || !mounted) return;
    _cambiarCantidadProducto(indice, cantidad);
  }

  List<LineaItemOrdenTrabajoInput> _armarLineas() {
    final lineas = <LineaItemOrdenTrabajoInput>[];
    for (final linea in _lineasTrabajo) {
      if (linea.montoController.text.trim().isEmpty) continue;
      lineas.add(LineaItemOrdenTrabajoInput(
        tipo: TipoLineaOrdenTrabajo.trabajo,
        descripcion: linea.descripcionController.text.trim(),
        monto: FormateadorMiles.desformatear(linea.montoController.text),
      ));
    }
    for (final linea in _lineasProducto) {
      lineas.add(LineaItemOrdenTrabajoInput(
        tipo: TipoLineaOrdenTrabajo.producto,
        varianteProductoId: linea.producto.varianteProductoId,
        cantidad: linea.cantidad,
      ));
    }
    return lineas;
  }

  Future<void> _guardar() async {
    final descripcion = _esCotizarExistente ? widget.descripcionExistente! : _descripcionController.text.trim();
    if (!_esCotizarExistente && descripcion.isEmpty) {
      setState(() => _error = 'La descripción es obligatoria.');
      return;
    }

    final lineasInvalidas =
        _lineasTrabajo.any((l) => l.descripcionController.text.trim().isEmpty || l.montoController.text.trim().isEmpty);
    if (lineasInvalidas) {
      setState(() => _error = 'Toda línea de Trabajo necesita descripción y un monto válido.');
      return;
    }

    final lineas = _armarLineas();
    if (_esCotizarExistente && lineas.isEmpty) {
      setState(() => _error = 'Agrega al menos una línea para cotizar este Ítem.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final notifier = ref.read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId).notifier);
    final ok = _esCotizarExistente
        ? await notifier.cotizarItem(itemId: widget.itemIdACotizar!, lineas: lineas)
        : await notifier.agregarItem(descripcion: descripcion, lineas: lineas.isEmpty ? null : lineas);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(ordenTrabajoDetalleProvider(widget.ordenTrabajoId)).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esCotizarExistente ? 'Cotizar: ${widget.descripcionExistente}' : 'Agregar Ítem'),
      content: SizedBox(
        width: 640,
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
              if (!_esCotizarExistente) ...[
                TextField(
                  key: const Key('editorItemDescripcion'),
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción del problema o solicitud'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Deja las líneas vacías si todavía hace falta evaluarlo — queda "Pendiente de evaluación".',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              for (var i = 0; i < _lineasTrabajo.length; i++) _filaLineaTrabajo(i),
              for (var i = 0; i < _lineasProducto.length; i++) _filaLineaProducto(i),
              const SizedBox(height: 8),
              if (_agregandoProducto) _buscadorProducto() else _botonesAgregar(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('editorItemGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _botonesAgregar() {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          key: const Key('editorItemAgregarTrabajo'),
          onPressed: _agregarLineaTrabajo,
          icon: const Icon(Icons.build_outlined),
          label: const Text('Línea de Trabajo'),
        ),
        OutlinedButton.icon(
          key: const Key('editorItemAgregarProducto'),
          onPressed: () => setState(() => _agregandoProducto = true),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Línea de Producto'),
        ),
      ],
    );
  }

  Widget _buscadorProducto() {
    final estado = ref.watch(busquedaProductosProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('editorItemBusquedaProducto'),
          controller: _busquedaController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Buscar Producto',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _agregandoProducto = false)),
          ),
          onChanged: (texto) => ref.read(busquedaProductosProvider.notifier).buscar(texto),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: estado.buscando
              ? const Center(child: CircularProgressIndicator())
              : estado.resultados.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 182,
                      ),
                      itemCount: estado.resultados.length,
                      itemBuilder: (context, index) {
                        final producto = estado.resultados[index];
                        return ProductoResultadoTile(
                          key: Key('editorItemProducto_${producto.varianteProductoId}'),
                          producto: producto,
                          onAgregar: () => _agregarProducto(producto),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _filaLineaTrabajo(int indice) {
    final linea = _lineasTrabajo[indice];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              key: Key('editorItemTrabajoDescripcion_$indice'),
              controller: linea.descripcionController,
              decoration: const InputDecoration(labelText: 'Trabajo'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('editorItemTrabajoMonto_$indice'),
              controller: linea.montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMiles()],
              decoration: const InputDecoration(labelText: 'Monto'),
            ),
          ),
          IconButton(
            key: Key('editorItemQuitarTrabajo_$indice'),
            onPressed: () => _quitarLineaTrabajo(indice),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _filaLineaProducto(int indice) {
    return Container(
      key: Key('editorItemLineaProducto_$indice'),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: PosColors.navy, borderRadius: BorderRadius.circular(8)),
      child: CarritoLineaTile(
        key: Key('editorItemCantidadProducto_$indice'),
        linea: _lineasProducto[indice],
        onCambiarCantidad: (cantidad) => _cambiarCantidadProducto(indice, cantidad),
        onQuitar: () => _quitarLineaProducto(indice),
        onEditarCantidad: () => _editarCantidadProducto(indice),
      ),
    );
  }
}
