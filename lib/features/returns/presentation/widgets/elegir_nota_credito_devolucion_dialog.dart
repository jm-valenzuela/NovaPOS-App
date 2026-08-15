import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/nota_credito_disponible_resumen.dart';
import '../providers/returns_providers.dart';

/// Lista las Notas de Crédito Disponibles de la Empresa (cualquier
/// Cliente, últimas 10) para reembolsar en efectivo ahora — el Cliente
/// vuelve más tarde con una Nota que le quedó Disponible de una
/// devolución anterior. Mismo estilo que RescatarCotizacionDialog; al
/// tocar una fila pide confirmación (acción con dinero real, distinto de
/// solo elegir algo) y, si se acepta, reembolsa de inmediato (ver
/// ReembolsarNotaCreditoCommand — distinto de RegistrarDevolucionCommand,
/// que reembolsa al momento de crear la Nota, no después).
class ElegirNotaCreditoDevolucionDialog extends ConsumerStatefulWidget {
  const ElegirNotaCreditoDevolucionDialog({super.key, required this.sesionCajaId});

  final String sesionCajaId;

  @override
  ConsumerState<ElegirNotaCreditoDevolucionDialog> createState() => _ElegirNotaCreditoDevolucionDialogState();
}

class _ElegirNotaCreditoDevolucionDialogState extends ConsumerState<ElegirNotaCreditoDevolucionDialog> {
  late Future<List<NotaCreditoDisponibleResumen>> _futuro;
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  NotaCreditoDisponibleResumen? _notaAConfirmar;
  bool _reembolsando = false;
  String? _error;

  static const _maximoResultados = 10;

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(returnsRepositoryProvider).listarNotasCreditoDisponibles();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<NotaCreditoDisponibleResumen> _filtrar(List<NotaCreditoDisponibleResumen> notas) {
    final resultado = _busqueda.isEmpty
        ? notas
        : notas.where((n) =>
            n.clienteNombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
            n.folio.toLowerCase().contains(_busqueda.toLowerCase()));
    return resultado.take(_maximoResultados).toList();
  }

  Future<void> _confirmarReembolso() async {
    final nota = _notaAConfirmar!;
    setState(() {
      _reembolsando = true;
      _error = null;
    });
    try {
      await ref.read(returnsRepositoryProvider).reembolsarNotaCredito(notaCreditoId: nota.id, sesionCajaId: widget.sesionCajaId);
      if (!mounted) return;
      Navigator.of(context).pop(nota);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reembolsando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notaAConfirmar != null) return _pasoConfirmar();

    return AlertDialog(
      title: const Text('Notas de crédito a devolver en efectivo'),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            TextField(
              key: const Key('devolucionBuscarNotaCredito'),
              controller: _busquedaController,
              decoration: const InputDecoration(
                labelText: 'Buscar por Cliente o RUT',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (texto) => setState(() => _busqueda = texto.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<NotaCreditoDisponibleResumen>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('No se pudieron cargar las Notas de Crédito: ${snapshot.error}'));
                  }
                  final notas = snapshot.data!;
                  if (notas.isEmpty) {
                    return const Center(child: Text('No hay Notas de Crédito Disponibles.'));
                  }
                  final filtradas = _filtrar(notas);
                  if (filtradas.isEmpty) {
                    return const Center(child: Text('Ninguna Nota de Crédito coincide con la búsqueda.'));
                  }
                  return ListView.separated(
                    itemCount: filtradas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final nota = filtradas[index];
                      return ListTile(
                        key: Key('devolucionNotaCreditoDisponible_${nota.id}'),
                        title: Text(nota.clienteNombre),
                        subtitle: Text('${nota.folio} · ${DateFormat('dd-MM-yyyy HH:mm').format(nota.fechaEmision.toLocal())}'),
                        trailing:
                            Text(MonedaFormatter.formatear(nota.montoTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => setState(() => _notaAConfirmar = nota),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }

  Widget _pasoConfirmar() {
    final nota = _notaAConfirmar!;
    return AlertDialog(
      title: const Text('Confirmar reembolso'),
      content: Text(
        '¿Reembolsar ${MonedaFormatter.formatear(nota.montoTotal)} en efectivo a ${nota.clienteNombre} (Nota ${nota.folio})?'
        '${_error != null ? '\n\nNo se pudo reembolsar: $_error' : ''}',
      ),
      actions: [
        TextButton(
          key: const Key('devolucionCancelarReembolso'),
          onPressed: _reembolsando ? null : () => setState(() => _notaAConfirmar = null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('devolucionConfirmarReembolso'),
          onPressed: _reembolsando ? null : _confirmarReembolso,
          child: _reembolsando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
