import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/registrar_documento_recibido_dialog.dart';

/// Todos los Documentos Recibidos (mercadería ligada a Orden de Compra +
/// Facturas Internas) a través de todos los Proveedores — pantalla global,
/// a pedido explícito del usuario: entrar Proveedor por Proveedor para
/// revisar documentos "no es efectivo, se supone que tendremos muchos
/// proveedores". Reemplaza el ícono que antes vivía en cada fila de
/// ProveedoresScreen.
class DocumentosRecibidosScreen extends ConsumerWidget {
  const DocumentosRecibidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(documentosRecibidosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos Recibidos')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevoDocumentoRecibidoBoton'),
        tooltip: 'Registrar Documento Recibido',
        onPressed: () => showDialog<bool>(context: context, builder: (_) => const RegistrarDocumentoRecibidoDialog()),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentosRecibidosProvider.notifier).cargar(),
        child: estado.cargando && estado.documentos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.documentos.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 96),
                        child: Center(child: Text('Sin Documentos Recibidos')),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: estado.documentos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final documento = estado.documentos[index];
                      final esFacturaInterna = documento.ordenCompraId == null;
                      return ListTile(
                        key: Key('documentoRecibido_${documento.id}'),
                        title: Text('${documento.proveedorNombre} · ${documento.tipoDocumento.etiqueta} N° ${documento.folio}'),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${documento.proveedorRut} · ${documento.fechaEmision.toLocal().toString().split(' ').first}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              key: const Key('chipFacturaInterna'),
                              label: Text(esFacturaInterna
                                  ? (documento.categoria != null ? 'Factura Interna · ${documento.categoria!.etiqueta}' : 'Factura Interna')
                                  : 'Mercadería'),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            if (documento.rutaArchivoRespaldo != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: const Key('documentoRecibidoVerRespaldo'),
                                icon: const Icon(Icons.attach_file, size: 18),
                                tooltip: 'Ver respaldo',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => launchUrl(
                                  Uri.parse('${ApiConfig.origin}${documento.rutaArchivoRespaldo}'),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Text(MonedaFormatter.formatear(documento.montoTotal)),
                      );
                    },
                  ),
      ),
    );
  }
}
