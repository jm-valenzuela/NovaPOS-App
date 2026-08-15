import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/proveedor.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/proveedor_form_dialog.dart';

class ProveedoresScreen extends ConsumerStatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  ConsumerState<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends ConsumerState<ProveedoresScreen> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(proveedoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoProveedorBoton'),
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('proveedoresBusqueda'),
              controller: _busquedaController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o RUT...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (texto) => ref.read(proveedoresProvider.notifier).cargar(texto: texto),
            ),
          ),
          if (estado.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(estado.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: estado.cargando
                ? const Center(child: CircularProgressIndicator())
                : estado.proveedores.isEmpty
                    ? const Center(child: Text('Sin Proveedores'))
                    : ListView.separated(
                        itemCount: estado.proveedores.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final proveedor = estado.proveedores[index];
                          return ListTile(
                            key: Key('proveedor_${proveedor.id}'),
                            title: Text(proveedor.nombre),
                            subtitle: Text('${proveedor.rut}${proveedor.telefono != null ? ' · ${proveedor.telefono}' : ''}'),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _abrirFormulario(context, existente: proveedor),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, {ProveedorResumen? existente}) async {
    await showDialog<bool>(context: context, builder: (_) => ProveedorFormDialog(existente: existente));
  }
}
