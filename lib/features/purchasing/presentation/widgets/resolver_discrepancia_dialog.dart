import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchasing_providers.dart';

class ResolverDiscrepanciaDialog extends ConsumerStatefulWidget {
  const ResolverDiscrepanciaDialog({super.key, required this.discrepanciaId});

  final String discrepanciaId;

  @override
  ConsumerState<ResolverDiscrepanciaDialog> createState() => _ResolverDiscrepanciaDialogState();
}

class _ResolverDiscrepanciaDialogState extends ConsumerState<ResolverDiscrepanciaDialog> {
  final _motivoController = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolver discrepancia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextField(
            key: const Key('resolverDiscrepanciaMotivo'),
            controller: _motivoController,
            decoration: const InputDecoration(labelText: 'Motivo'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('resolverDiscrepanciaConfirmar'),
          onPressed: _guardando ? null : _resolver,
          child: _guardando
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Resolver'),
        ),
      ],
    );
  }

  Future<void> _resolver() async {
    final motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      setState(() => _error = 'El motivo es obligatorio.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final exito = await ref.read(discrepanciasProvider.notifier).resolver(discrepanciaId: widget.discrepanciaId, motivo: motivo);

    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = ref.read(discrepanciasProvider).error ?? 'No se pudo resolver la discrepancia.';
      });
    }
  }
}
