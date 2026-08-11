import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_admin_providers.dart';
import '../widgets/nuevo_nombre_dialog.dart';

/// Mantención de Marcas — a diferencia de Producto/Variante, el backend solo
/// soporta listar y crear (sin editar/desactivar Marca), así que la
/// pantalla es deliberadamente simple: una lista y un FAB de alta.
class MarcasAdminScreen extends ConsumerWidget {
  const MarcasAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marcasAsync = ref.watch(marcasAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Marcas')),
      body: marcasAsync.when(
        data: (marcas) => marcas.isEmpty
            ? const Center(child: Text('Sin Marcas creadas todavía.'))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(marcasAdminProvider.future),
                child: ListView.separated(
                  itemCount: marcas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final marca = marcas[index];
                    return ListTile(key: Key('marca_${marca.id}'), title: Text(marca.nombre));
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudieron cargar las Marcas: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('marcasNuevaBoton'),
        onPressed: () async {
          final creada = await showDialog<bool>(
            context: context,
            builder: (_) => NuevoNombreDialog(
              titulo: 'Nueva Marca',
              etiquetaCampo: 'Nombre',
              onCrear: (nombre) => ref.read(catalogAdminRepositoryProvider).crearMarca(nombre),
            ),
          );
          if (creada ?? false) ref.invalidate(marcasAdminProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
