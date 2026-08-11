import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/clasificacion.dart';
import '../providers/catalog_admin_providers.dart';
import '../widgets/nuevo_nombre_dialog.dart';

/// Mantención de la jerarquía Departamento → SubDepartamento → Clase →
/// Subclase — árbol expandible de solo alta (mismo motivo que
/// MarcasAdminScreen: el backend no soporta editar/desactivar estos
/// niveles). Cada nivel se carga perezosamente al expandir su padre.
class CategoriasAdminScreen extends ConsumerWidget {
  const CategoriasAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departamentosAsync = ref.watch(departamentosAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: departamentosAsync.when(
        data: (departamentos) => departamentos.isEmpty
            ? const Center(child: Text('Sin Departamentos creados todavía.'))
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [for (final departamento in departamentos) _DepartamentoTile(departamento: departamento)],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudieron cargar los Departamentos: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('categoriasNuevoDepartamentoBoton'),
        onPressed: () => _crear(
          context: context,
          titulo: 'Nuevo Departamento',
          onCrear: (nombre) => ref.read(catalogAdminRepositoryProvider).crearDepartamento(nombre),
          onCreado: () => ref.invalidate(departamentosAdminProvider),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _crear({
  required BuildContext context,
  required String titulo,
  required Future<void> Function(String nombre) onCrear,
  required VoidCallback onCreado,
}) async {
  final creado = await showDialog<bool>(
    context: context,
    builder: (_) => NuevoNombreDialog(titulo: titulo, etiquetaCampo: 'Nombre', onCrear: onCrear),
  );
  if (creado ?? false) onCreado();
}

class _DepartamentoTile extends ConsumerWidget {
  const _DepartamentoTile({required this.departamento});

  final Departamento departamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subDepartamentosAsync = ref.watch(subDepartamentosAdminProvider(departamento.id));

    return ExpansionTile(
      key: Key('categoriaDepartamento_${departamento.id}'),
      title: Text(departamento.nombre),
      trailing: IconButton(
        key: Key('categoriaNuevoSubDepartamento_${departamento.id}'),
        icon: const Icon(Icons.add),
        tooltip: 'Nuevo SubDepartamento',
        onPressed: () => _crear(
          context: context,
          titulo: 'Nuevo SubDepartamento en "${departamento.nombre}"',
          onCrear: (nombre) => ref.read(catalogAdminRepositoryProvider).crearSubDepartamento(departamento.id, nombre),
          onCreado: () => ref.invalidate(subDepartamentosAdminProvider(departamento.id)),
        ),
      ),
      children: [
        subDepartamentosAsync.when(
          data: (subDepartamentos) => subDepartamentos.isEmpty
              ? const Padding(padding: EdgeInsets.only(left: 32, bottom: 8), child: Text('Sin SubDepartamentos'))
              : Column(
                  children: [for (final s in subDepartamentos) _SubDepartamentoTile(subDepartamento: s)],
                ),
          loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          error: (error, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $error')),
        ),
      ],
    );
  }
}

class _SubDepartamentoTile extends ConsumerWidget {
  const _SubDepartamentoTile({required this.subDepartamento});

  final SubDepartamento subDepartamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clasesAsync = ref.watch(clasesAdminProvider(subDepartamento.id));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        key: Key('categoriaSubDepartamento_${subDepartamento.id}'),
        title: Text(subDepartamento.nombre),
        trailing: IconButton(
          key: Key('categoriaNuevaClase_${subDepartamento.id}'),
          icon: const Icon(Icons.add),
          tooltip: 'Nueva Clase',
          onPressed: () => _crear(
            context: context,
            titulo: 'Nueva Clase en "${subDepartamento.nombre}"',
            onCrear: (nombre) => ref.read(catalogAdminRepositoryProvider).crearClase(subDepartamento.id, nombre),
            onCreado: () => ref.invalidate(clasesAdminProvider(subDepartamento.id)),
          ),
        ),
        children: [
          clasesAsync.when(
            data: (clases) => clases.isEmpty
                ? const Padding(padding: EdgeInsets.only(left: 32, bottom: 8), child: Text('Sin Clases'))
                : Column(children: [for (final c in clases) _ClaseTile(clase: c)]),
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (error, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}

class _ClaseTile extends ConsumerWidget {
  const _ClaseTile({required this.clase});

  final Clase clase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subclasesAsync = ref.watch(subclasesAdminProvider(clase.id));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        key: Key('categoriaClase_${clase.id}'),
        title: Text(clase.nombre),
        trailing: IconButton(
          key: Key('categoriaNuevaSubclase_${clase.id}'),
          icon: const Icon(Icons.add),
          tooltip: 'Nueva Subclase',
          onPressed: () => _crear(
            context: context,
            titulo: 'Nueva Subclase en "${clase.nombre}"',
            onCrear: (nombre) => ref.read(catalogAdminRepositoryProvider).crearSubclase(clase.id, nombre),
            onCreado: () => ref.invalidate(subclasesAdminProvider(clase.id)),
          ),
        ),
        children: [
          subclasesAsync.when(
            data: (subclases) => subclases.isEmpty
                ? const Padding(padding: EdgeInsets.only(left: 32, bottom: 8), child: Text('Sin Subclases'))
                : Column(
                    children: [
                      for (final subclase in subclases)
                        ListTile(
                          key: Key('categoriaSubclase_${subclase.id}'),
                          contentPadding: const EdgeInsets.only(left: 32, right: 16),
                          title: Text(subclase.nombre),
                        ),
                    ],
                  ),
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (error, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}
