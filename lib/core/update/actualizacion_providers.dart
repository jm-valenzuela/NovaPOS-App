import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chequeo_version.dart';

/// Sondea flutter_service_worker.js cada 10 minutos — a diferencia de
/// una PWA normal, esta app no registra Service Worker (ver
/// web/index.html), así que el navegador nunca avisa solo que hay una
/// versión nueva ni la sirve automáticamente; esto es lo único que
/// detecta un deploy nuevo mientras el POS sigue abierto, sin forzar el
/// reload por su cuenta (podría cortar una venta a medio hacer).
class ActualizacionController extends StateNotifier<bool> {
  ActualizacionController() : super(false) {
    _iniciar();
  }

  Timer? _timer;
  String? _firmaInicial;

  Future<void> _iniciar() async {
    _firmaInicial = await obtenerFirmaVersionServida();
    if (_firmaInicial == null) return; // plataforma no-web, o el fetch falló: no molestar
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _chequear());
  }

  Future<void> _chequear() async {
    if (state) return; // ya se avisó, no hace falta seguir chequeando
    final firmaActual = await obtenerFirmaVersionServida();
    if (firmaActual != null && firmaActual != _firmaInicial) {
      state = true;
    }
  }

  void recargar() => recargarPagina();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final actualizacionDisponibleProvider = StateNotifierProvider<ActualizacionController, bool>((ref) {
  return ActualizacionController();
});
