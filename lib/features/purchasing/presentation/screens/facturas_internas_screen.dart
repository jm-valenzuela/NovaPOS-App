import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/utils/moneda_formatter.dart';
import '../providers/purchasing_providers.dart';
import '../widgets/registrar_factura_interna_dialog.dart';

/// Facturas de proveedor que no constituyen compra de productos o materia
/// prima (gastos, insumos, servicios, activo fijo, etc.) — pantalla propia
/// e independiente de Documentos Recibidos por Proveedor, con listado
/// global a través de todos los Proveedores (ver ListarFacturasInternasQuery),
/// a pedido explícito del usuario. El registro por Proveedor sigue
/// existiendo en Compras → Documentos Recibidos, sin cambios.
class FacturasInternasScreen extends ConsumerWidget {
  const FacturasInternasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(facturasInternasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facturas Internas')),
      floatingActionButton: FloatingActionButton(
        key: const Key('nuevaFacturaInternaBoton'),
        tooltip: 'Registrar Factura Interna',
        onPressed: () => showDialog<bool>(context: context, builder: (_) => const RegistrarFacturaInternaDialog()),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(facturasInternasProvider.notifier).cargar(),
        child: estado.cargando && estado.facturas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : estado.facturas.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 96),
                        child: Center(child: Text('Sin Facturas Internas registradas')),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: estado.facturas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final factura = estado.facturas[index];
                      return ListTile(
                        key: Key('facturaInterna_${factura.id}'),
                        title: Text('${factura.proveedorNombre} · ${factura.tipoDocumento.etiqueta} N° ${factura.folio}'),
                        subtitle: Row(
                          children: [
                            Text('${factura.proveedorRut} · ${factura.fechaEmision.toLocal().toString().split(' ').first}'),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(factura.categoria.etiqueta),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            if (factura.rutaArchivoRespaldo != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: const Key('facturaInternaConRespaldo'),
                                icon: const Icon(Icons.attach_file, size: 18),
                                tooltip: 'Ver respaldo',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => launchUrl(
                                  Uri.parse('${ApiConfig.origin}${factura.rutaArchivoRespaldo}'),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Text(MonedaFormatter.formatear(factura.montoTotal)),
                      );
                    },
                  ),
      ),
    );
  }
}
