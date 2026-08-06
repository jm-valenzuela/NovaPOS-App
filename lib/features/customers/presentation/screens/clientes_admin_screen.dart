import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cliente_resumen.dart';
import '../providers/customer_admin_providers.dart';
import '../widgets/cliente_form_dialog.dart';

class ClientesAdminScreen extends ConsumerStatefulWidget {
  const ClientesAdminScreen({super.key});

  @override
  ConsumerState<ClientesAdminScreen> createState() => _ClientesAdminScreenState();
}

class _ClientesAdminScreenState extends ConsumerState<ClientesAdminScreen> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(clientesAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoClienteBoton'),
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('clientesBusqueda'),
              controller: _busquedaController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o RUT...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (texto) => ref.read(clientesAdminProvider.notifier).cargar(texto: texto),
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
                : estado.clientes.isEmpty
                    ? const Center(child: Text('Sin Clientes'))
                    : ListView.separated(
                        itemCount: estado.clientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cliente = estado.clientes[index];
                          return ListTile(
                            key: Key('cliente_${cliente.id}'),
                            title: Text(cliente.nombre),
                            subtitle: Text(cliente.rut ?? 'Sin RUT'),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _abrirFormulario(context, existente: cliente),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, {ClienteResumen? existente}) async {
    await showDialog<bool>(context: context, builder: (_) => ClienteFormDialog(existente: existente));
  }
}
