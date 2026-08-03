import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_form_providers.dart';
import 'selector_con_alta.dart';

/// Los 5 selectores de clasificación (Departamento→SubDepartamento→Clase→
/// Subclase, y Marca) compuestos juntos — usado tanto al crear un Producto
/// como al cambiar la clasificación de uno existente.
class ClasificacionCascade extends ConsumerWidget {
  const ClasificacionCascade({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(catalogFormProvider);
    final controller = ref.read(catalogFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectorConAlta(
          key: const Key('catalogoDepartamento'),
          label: 'Departamento',
          opciones: estado.departamentos.map((d) => (id: d.id, nombre: d.nombre)).toList(),
          valorSeleccionado: estado.departamentoId,
          onSeleccionar: controller.seleccionarDepartamento,
          onCrearNuevo: controller.crearDepartamento,
          cargando: estado.cargandoInicial,
        ),
        const SizedBox(height: 12),
        SelectorConAlta(
          key: const Key('catalogoSubDepartamento'),
          label: 'SubDepartamento',
          opciones: estado.subDepartamentos.map((s) => (id: s.id, nombre: s.nombre)).toList(),
          valorSeleccionado: estado.subDepartamentoId,
          onSeleccionar: controller.seleccionarSubDepartamento,
          onCrearNuevo: controller.crearSubDepartamento,
          habilitado: estado.departamentoId != null,
          cargando: estado.cargandoNivel,
        ),
        const SizedBox(height: 12),
        SelectorConAlta(
          key: const Key('catalogoClase'),
          label: 'Clase',
          opciones: estado.clases.map((c) => (id: c.id, nombre: c.nombre)).toList(),
          valorSeleccionado: estado.claseId,
          onSeleccionar: controller.seleccionarClase,
          onCrearNuevo: controller.crearClase,
          habilitado: estado.subDepartamentoId != null,
          cargando: estado.cargandoNivel,
        ),
        const SizedBox(height: 12),
        SelectorConAlta(
          key: const Key('catalogoSubclase'),
          label: 'Subclase',
          opciones: estado.subclases.map((s) => (id: s.id, nombre: s.nombre)).toList(),
          valorSeleccionado: estado.subclaseId,
          onSeleccionar: controller.seleccionarSubclase,
          onCrearNuevo: controller.crearSubclase,
          habilitado: estado.claseId != null,
          cargando: estado.cargandoNivel,
        ),
        const SizedBox(height: 12),
        SelectorConAlta(
          key: const Key('catalogoMarca'),
          label: 'Marca',
          opciones: estado.marcas.map((m) => (id: m.id, nombre: m.nombre)).toList(),
          valorSeleccionado: estado.marcaId,
          onSeleccionar: controller.seleccionarMarca,
          onCrearNuevo: controller.crearMarca,
          cargando: estado.cargandoInicial,
        ),
      ],
    );
  }
}
