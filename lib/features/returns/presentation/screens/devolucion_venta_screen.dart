import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../../sales/presentation/providers/pos_providers.dart' show cajasProvider;
import '../../domain/models/venta_confirmada_resumen.dart';
import '../providers/returns_providers.dart';

/// Atención de Clientes: elegir la Venta Confirmada (Boleta o Factura) a
/// devolver — mismo patrón que CotizacionesScreen (selector de Sucursal +
/// búsqueda), pero acá el resultado de tocar una fila es ir al paso de
/// detalle (ver RegistrarDevolucionScreen), no un popup transitorio: esta
/// pantalla vive en el Home, no en el POS, así que no depende de una Caja
/// ni de una Sesión Abierta.
class DevolucionVentaScreen extends ConsumerStatefulWidget {
  const DevolucionVentaScreen({super.key});

  @override
  ConsumerState<DevolucionVentaScreen> createState() => _DevolucionVentaScreenState();
}

class _DevolucionVentaScreenState extends ConsumerState<DevolucionVentaScreen> {
  String? _sucursalId;
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<VentaConfirmadaResumen> _filtrar(List<VentaConfirmadaResumen> ventas) {
    if (_busqueda.isEmpty) return ventas;
    final texto = _busqueda.toLowerCase();
    return ventas
        .where((v) => v.clienteNombre.toLowerCase().contains(texto) || (v.clienteRut?.toLowerCase().contains(texto) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cajasAsync = ref.watch(cajasProvider);

    ref.listen(cajasProvider, (previo, actual) {
      actual.whenData((cajas) {
        if (_sucursalId == null && cajas.isNotEmpty) {
          final distintas = <String>{for (final c in cajas) c.sucursalId};
          if (distintas.length == 1) setState(() => _sucursalId = distintas.first);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Devolución de productos')),
      body: cajasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar la Sucursal: $error')),
        data: (cajas) {
          final sucursales = <String, String>{for (final c in cajas) c.sucursalId: c.nombreSucursal};
          if (sucursales.isEmpty) {
            return const Center(child: Text('Esta Empresa no tiene ninguna Sucursal configurada.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    if (sucursales.length > 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<String>(
                          key: const Key('devolucionVentaSelectorSucursal'),
                          value: _sucursalId,
                          hint: const Text('Elige una Sucursal'),
                          items: sucursales.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                          onChanged: (sucursalId) => setState(() => _sucursalId = sucursalId),
                        ),
                      ),
                    TextField(
                      key: const Key('devolucionVentaBuscar'),
                      controller: _busquedaController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por Cliente o RUT',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (texto) => setState(() => _busqueda = texto.trim()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _sucursalId == null
                    ? const Center(child: Text('Elige con qué Sucursal vas a trabajar.'))
                    : _ListadoVentas(sucursalId: _sucursalId!, filtrar: _filtrar),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListadoVentas extends ConsumerStatefulWidget {
  const _ListadoVentas({required this.sucursalId, required this.filtrar});

  final String sucursalId;
  final List<VentaConfirmadaResumen> Function(List<VentaConfirmadaResumen>) filtrar;

  @override
  ConsumerState<_ListadoVentas> createState() => _ListadoVentasState();
}

class _ListadoVentasState extends ConsumerState<_ListadoVentas> {
  late Future<List<VentaConfirmadaResumen>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(returnsRepositoryProvider).listarVentasConfirmadas(widget.sucursalId);
  }

  @override
  void didUpdateWidget(covariant _ListadoVentas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sucursalId != widget.sucursalId) {
      _futuro = ref.read(returnsRepositoryProvider).listarVentasConfirmadas(widget.sucursalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VentaConfirmadaResumen>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('No se pudieron cargar las Ventas: ${snapshot.error}'));
        }
        final ventas = snapshot.data!;
        if (ventas.isEmpty) {
          return const Center(child: Text('No hay Ventas Confirmadas en esta Sucursal.'));
        }
        final filtradas = widget.filtrar(ventas);
        if (filtradas.isEmpty) {
          return const Center(child: Text('Ninguna Venta coincide con la búsqueda.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final venta = filtradas[index];
            return Card(
              child: ListTile(
                key: Key('devolucionVentaItem_${venta.ventaId}'),
                title: Text(venta.clienteNombre),
                subtitle: Text(
                  '${DateFormat('dd-MM-yyyy HH:mm').format(venta.fechaConfirmacion.toLocal())} · '
                  '${venta.cantidadLineas} ${venta.cantidadLineas == 1 ? "producto" : "productos"}',
                ),
                trailing: Text(MonedaFormatter.formatear(venta.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => context.push('/devolucion-venta/${venta.ventaId}'),
              ),
            );
          },
        );
      },
    );
  }
}
