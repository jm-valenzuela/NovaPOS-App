import 'package:flutter/material.dart';

/// Dropdown genérico + opción "Nueva..." al final que abre un diálogo de
/// texto simple — reutilizado para Departamento/SubDepartamento/Clase/
/// Subclase/Marca, los 5 niveles de clasificación de Catalog.
class SelectorConAlta extends StatelessWidget {
  const SelectorConAlta({
    super.key,
    required this.label,
    required this.opciones,
    required this.valorSeleccionado,
    required this.onSeleccionar,
    required this.onCrearNuevo,
    this.habilitado = true,
    this.cargando = false,
  });

  final String label;
  final List<({String id, String nombre})> opciones;
  final String? valorSeleccionado;
  final ValueChanged<String> onSeleccionar;
  final ValueChanged<String> onCrearNuevo;
  final bool habilitado;
  final bool cargando;

  static const _valorNuevo = '__nuevo__';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: cargando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
      value: valorSeleccionado,
      items: [
        ...opciones.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombre, overflow: TextOverflow.ellipsis))),
        const DropdownMenuItem(value: _valorNuevo, child: Text('+ Nueva...')),
      ],
      onChanged: !habilitado || cargando
          ? null
          : (valor) async {
              if (valor == null) return;
              if (valor == _valorNuevo) {
                final nombre = await _pedirNombre(context, label);
                if (nombre != null && nombre.trim().isNotEmpty) onCrearNuevo(nombre.trim());
                return;
              }
              onSeleccionar(valor);
            },
    );
  }

  Future<String?> _pedirNombre(BuildContext context, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nueva $label'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
