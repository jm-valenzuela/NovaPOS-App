import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/returns_api.dart';
import '../../data/returns_repository_impl.dart';
import '../../domain/models/linea_devolucion_input.dart';
import '../../domain/models/nota_credito_cliente_resumen.dart';
import '../../domain/returns_repository.dart';

final returnsApiProvider = Provider<ReturnsApi>((ref) => ReturnsApi(ref.watch(apiClientProvider)));

final returnsRepositoryProvider = Provider<ReturnsRepository>((ref) => ReturnsRepositoryImpl(ref.watch(returnsApiProvider)));

/// Notas de Crédito Disponibles de un Cliente — familia por clienteId, la
/// consulta el Checkout para ofrecerlas como medio de pago.
final notasDisponiblesProvider =
    FutureProvider.autoDispose.family<List<NotaCreditoClienteResumen>, String>((ref, clienteId) {
  return ref.watch(returnsRepositoryProvider).listarNotasCreditoCliente(clienteId, soloDisponibles: true);
});

class RegistrarDevolucionState {
  const RegistrarDevolucionState({this.registrando = false, this.error});

  final bool registrando;
  final String? error;

  RegistrarDevolucionState copyWith({bool? registrando, String? error, bool limpiarError = false}) {
    return RegistrarDevolucionState(
      registrando: registrando ?? this.registrando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

/// Controller de un único uso — registra la devolución elegida en
/// RegistrarDevolucionScreen y expone el estado de carga/error del envío.
class RegistrarDevolucionController extends StateNotifier<RegistrarDevolucionState> {
  RegistrarDevolucionController(this._repository) : super(const RegistrarDevolucionState());

  final ReturnsRepository _repository;

  Future<String?> registrar({
    required String ventaOrigenId,
    required String clienteId,
    required List<LineaDevolucionInput> lineas,
    required String motivo,
    required bool reembolsarEnEfectivo,
    String? sesionCajaId,
  }) async {
    state = state.copyWith(registrando: true, limpiarError: true);
    try {
      final id = await _repository.registrarDevolucion(
        ventaOrigenId: ventaOrigenId,
        clienteId: clienteId,
        lineas: lineas,
        motivo: motivo,
        reembolsarEnEfectivo: reembolsarEnEfectivo,
        sesionCajaId: sesionCajaId,
      );
      state = state.copyWith(registrando: false);
      return id;
    } catch (e) {
      state = state.copyWith(registrando: false, error: e.toString());
      return null;
    }
  }
}

final registrarDevolucionProvider =
    StateNotifierProvider.autoDispose<RegistrarDevolucionController, RegistrarDevolucionState>((ref) {
  return RegistrarDevolucionController(ref.watch(returnsRepositoryProvider));
});
