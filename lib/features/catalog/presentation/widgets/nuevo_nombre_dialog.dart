import 'package:flutter/material.dart';

/// Diálogo genérico "nombre + Guardar", reutilizado por MarcasAdminScreen y
/// CategoriasAdminScreen para dar de alta Marca/Departamento/SubDepartamento/
/// Clase/Subclase — los 5 niveles solo exigen un nombre no vacío (ver
/// CatalogAdminRepository.crearMarca/crearDepartamento/etc.), así que no
/// amerita un diálogo propio por nivel.
class NuevoNombreDialog extends StatefulWidget {
  const NuevoNombreDialog({super.key, required this.titulo, required this.etiquetaCampo, required this.onCrear});

  final String titulo;
  final String etiquetaCampo;

  /// Lanza si falla — el diálogo captura la excepción y muestra su mensaje.
  final Future<void> Function(String nombre) onCrear;

  @override
  State<NuevoNombreDialog> createState() => _NuevoNombreDialogState();
}

class _NuevoNombreDialogState extends State<NuevoNombreDialog> {
  final _controller = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          TextField(
            key: const Key('nuevoNombreCampo'),
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.etiquetaCampo),
            onSubmitted: (_) => _guardar(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('nuevoNombreGuardar'),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.onCrear(nombre);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar: $e';
      });
    }
  }
}
