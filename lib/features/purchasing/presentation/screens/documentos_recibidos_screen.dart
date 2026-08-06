import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/registrar_documento_recibido_dialog.dart';

class DocumentosRecibidosScreen extends ConsumerWidget {
  const DocumentosRecibidosScreen({super.key, required this.proveedorId, required this.proveedorNombre, this.rutProveedor});

  final String proveedorId;
  final String proveedorNombre;
  final String? rutProveedor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(documentosRecibidosProvider(proveedorId));

    return Scaffold(
      appBar: AppBar(title: Text('Documentos de $proveedorNombre')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoDocumentoRecibidoBoton'),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => RegistrarDocumentoRecibidoDialog(proveedorId: proveedorId, rutProveedor: rutProveedor),
        ),
        child: const Icon(Icons.add),
      ),
      body: estado.cargando
          ? const Center(child: CircularProgressIndicator())
          : estado.documentos.isEmpty
              ? const Center(child: Text('Sin Documentos Recibidos'))
              : ListView.separated(
                  itemCount: estado.documentos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final documento = estado.documentos[index];
                    return ListTile(
                      key: Key('documentoRecibido_${documento.id}'),
                      title: Text('${documento.tipoDocumento.etiqueta} N° ${documento.folio}'),
                      subtitle: Text(documento.fechaEmision.toLocal().toString().split(' ').first),
                      trailing: Text(MonedaFormatter.formatear(documento.montoTotal)),
                    );
                  },
                ),
    );
  }
}
