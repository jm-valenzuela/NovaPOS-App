import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customers/domain/models/cliente_resumen.dart';
import '../providers/pos_providers.dart';
import 'nuevo_cliente_pos_dialog.dart';

/// Devuelve el ClienteResumen elegido, o null (= "Cliente Genérico",
/// mismo criterio que usa el backend cuando CrearVentaCommand no recibe
/// ClienteId) — ver PosScreen._elegirCliente para el resto del contrato.
/// permitirClienteGenerico=false oculta esa opción — usar donde el Cliente
/// Genérico no es válido (ej. Nota de Crédito: siempre nominativa, ver
/// RegistrarDevolucionScreen).
class SelectorClienteDialog extends ConsumerStatefulWidget {
  const SelectorClienteDialog({super.key, this.permitirClienteGenerico = true});

  final bool permitirClienteGenerico;

  @override
  ConsumerState<SelectorClienteDialog> createState() => _SelectorClienteDialogState();
}

class _SelectorClienteDialogState extends ConsumerState<SelectorClienteDialog> {
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carga inicial con la lista vacía — el backend devuelve "los más
    // recientes" cuando no hay texto, mismo criterio que BuscarProductos.
    // Llamada directa (no microtask): buscar() solo arma un Timer, no
    // dispara ningún setState sincrónico durante el build.
    ref.read(busquedaClientesProvider.notifier).buscar('');
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Abre el alta rápida y, si se creó un Cliente, cierra este selector con
  /// ese Cliente ya elegido — evita un segundo paso de "ahora búscalo y
  /// tócalo en la lista".
  Future<void> _crearCliente(BuildContext context) async {
    final creado = await showDialog<ClienteResumen>(
      context: context,
      builder: (_) => const NuevoClientePosDialog(),
    );
    if (creado == null || !context.mounted) return;
    Navigator.of(context).pop(creado);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(busquedaClientesProvider);

    return AlertDialog(
      title: const Text('Elegir Cliente'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const Key('selectorClienteBusqueda'),
              controller: _busquedaController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o RUT',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: estado.buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              onChanged: (texto) => ref.read(busquedaClientesProvider.notifier).buscar(texto),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: estado.resultados.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: estado.resultados.length,
                      itemBuilder: (context, index) {
                        final cliente = estado.resultados[index];
                        return ListTile(
                          key: Key('selectorClienteResultado_${cliente.id}'),
                          title: Text(cliente.nombre),
                          subtitle: cliente.rut != null ? Text(cliente.rut!) : null,
                          onTap: () => Navigator.of(context).pop(cliente),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('selectorClienteCancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          key: const Key('selectorClienteNuevo'),
          onPressed: () => _crearCliente(context),
          child: const Text('Nuevo Cliente'),
        ),
        if (widget.permitirClienteGenerico)
          TextButton(
            key: const Key('selectorClienteGenerico'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Usar Cliente Genérico'),
          ),
      ],
    );
  }
}
