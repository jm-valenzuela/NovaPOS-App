import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/unidad_medida.dart';
import '../providers/catalog_admin_providers.dart';
import '../providers/catalog_form_providers.dart';
import '../widgets/clasificacion_cascade.dart';
import '../widgets/promocion_grupo_field.dart';

/// Crea un Producto y su primera Variante juntos (mismo criterio que
/// CrearProductoCommand en el backend) — editar Producto/Variantes
/// existentes se hace con diálogos más chicos desde ProductosAdminScreen,
/// no en esta pantalla.
class CatalogFormScreen extends ConsumerStatefulWidget {
  const CatalogFormScreen({super.key});

  @override
  ConsumerState<CatalogFormScreen> createState() => _CatalogFormScreenState();
}

class _CatalogFormScreenState extends ConsumerState<CatalogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _skuController = TextEditingController();
  final _precioController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _colorController = TextEditingController();
  final _tallaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _cantidadMinimaDescuentoController = TextEditingController();
  final _porcentajeDescuentoController = TextEditingController();
  PromocionGrupoValor _promocionGrupo = const PromocionGrupoValor();
  int _unidadMedida = 0;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _skuController.dispose();
    _precioController.dispose();
    _codigoBarrasController.dispose();
    _colorController.dispose();
    _tallaController.dispose();
    _ubicacionController.dispose();
    _cantidadMinimaDescuentoController.dispose();
    _porcentajeDescuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(catalogFormProvider);

    ref.listen(catalogFormProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      if (actual.resultado != null && previo?.resultado == null) {
        ref.read(productosAdminProvider.notifier).cargar();
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Producto', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('nombreProducto'),
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('descripcionProducto'),
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 20),
              Text('Clasificación', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const ClasificacionCascade(),
              const SizedBox(height: 20),
              Text('Primera Variante', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('skuVariante'),
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El SKU es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('precioVariante'),
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio de venta'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final numero = double.tryParse(v ?? '');
                  if (numero == null || numero < 0) return 'Ingresa un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const Key('unidadMedidaVariante'),
                decoration: const InputDecoration(labelText: 'Unidad de medida'),
                value: _unidadMedida,
                items: UnidadMedida.values
                    .map((u) => DropdownMenuItem(value: u.valor, child: Text(u.nombre)))
                    .toList(),
                onChanged: (valor) => setState(() => _unidadMedida = valor ?? 0),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('codigoBarrasVariante'),
                controller: _codigoBarrasController,
                decoration: const InputDecoration(labelText: 'Código de barras (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('colorVariante'),
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tallaVariante'),
                controller: _tallaController,
                decoration: const InputDecoration(labelText: 'Talla (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('ubicacionVariante'),
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación física (opcional)'),
              ),
              const SizedBox(height: 20),
              Text('Descuento por volumen (opcional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Ej. "Desde 15 unidades, 5% dto." — deja ambos campos vacíos si no aplica.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('cantidadMinimaDescuentoVariante'),
                controller: _cantidadMinimaDescuentoController,
                decoration: const InputDecoration(labelText: 'Cantidad mínima'),
                keyboardType: TextInputType.number,
                validator: (v) => _validarDescuentoVolumen(cantidadTexto: v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('porcentajeDescuentoVariante'),
                controller: _porcentajeDescuentoController,
                decoration: const InputDecoration(labelText: '% de descuento'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _validarDescuentoVolumen(porcentajeTexto: v),
              ),
              const SizedBox(height: 20),
              Text('Promoción por grupo (opcional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Ej. "2x1", "6x5", o "segundo producto con % dto." — no se combina con el descuento por volumen de arriba.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              PromocionGrupoField(onChanged: (valor) => _promocionGrupo = valor),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submitCrearProducto'),
                  onPressed: (estado.guardando || !estado.clasificacionCompleta) ? null : _enviar,
                  child: estado.guardando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Crear Producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ambos campos van juntos: uno sin el otro no tiene sentido (mismo
  /// criterio que VarianteProducto.ValidarDescuentoVolumen en el backend).
  String? _validarDescuentoVolumen({String? cantidadTexto, String? porcentajeTexto}) {
    final cantidad = (cantidadTexto ?? _cantidadMinimaDescuentoController.text).trim();
    final porcentaje = (porcentajeTexto ?? _porcentajeDescuentoController.text).trim();

    if (cantidad.isEmpty && porcentaje.isEmpty) return null;
    if (cantidad.isEmpty || porcentaje.isEmpty) return 'Completa ambos campos o deja los dos vacíos';

    final cantidadNum = int.tryParse(cantidad);
    if (cantidadNum == null || cantidadNum < 2) return 'Debe ser al menos 2';

    final porcentajeNum = double.tryParse(porcentaje);
    if (porcentajeNum == null || porcentajeNum <= 0 || porcentajeNum > 100) return 'Debe estar entre 1 y 100';

    return null;
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cantidadVolumen = int.tryParse(_cantidadMinimaDescuentoController.text.trim());
    final porcentajeVolumen = double.tryParse(_porcentajeDescuentoController.text.trim());
    if ((cantidadVolumen != null || porcentajeVolumen != null) && _promocionGrupo.cantidadPorGrupo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes combinar el descuento por volumen con una promoción por grupo — elige solo uno.')),
      );
      return;
    }

    ref.read(catalogFormProvider.notifier).crearProducto(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
          sku: _skuController.text.trim(),
          precioVenta: double.parse(_precioController.text),
          unidadMedida: _unidadMedida,
          codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
          color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
          talla: _tallaController.text.trim().isEmpty ? null : _tallaController.text.trim(),
          ubicacionFisica: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
          cantidadMinimaDescuentoVolumen: cantidadVolumen,
          porcentajeDescuentoVolumen: porcentajeVolumen,
          cantidadPorGrupoPromocion: _promocionGrupo.cantidadPorGrupo,
          porcentajeDescuentoUnidadPromocion: _promocionGrupo.porcentajeDescuentoUnidad,
        );
  }
}
