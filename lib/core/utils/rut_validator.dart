/// Validación del RUT chileno (módulo 11) — mismo algoritmo que usa el
/// backend (ver Rut.cs en NovaPOS.Domain) para no aceptar en el cliente
/// algo que el servidor va a rechazar de todas formas.
class RutValidator {
  RutValidator._();

  /// Acepta con o sin puntos/guión (ej. "12.345.678-5" o "12345678-5").
  static bool esValido(String rutCompleto) {
    final limpio = _limpiar(rutCompleto);
    if (limpio.length < 2) return false;

    final cuerpo = limpio.substring(0, limpio.length - 1);
    final dvIngresado = limpio.substring(limpio.length - 1).toUpperCase();

    if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

    return _calcularDv(cuerpo) == dvIngresado;
  }

  /// Formatea a "XX.XXX.XXX-X" para mostrar — no usar el resultado para validar, solo para presentación.
  static String formatear(String rutCompleto) {
    final limpio = _limpiar(rutCompleto);
    if (limpio.length < 2) return rutCompleto;

    final cuerpo = limpio.substring(0, limpio.length - 1);
    final dv = limpio.substring(limpio.length - 1).toUpperCase();

    final buffer = StringBuffer();
    for (var i = 0; i < cuerpo.length; i++) {
      final posicionDesdeElFinal = cuerpo.length - i;
      buffer.write(cuerpo[i]);
      if (posicionDesdeElFinal > 1 && posicionDesdeElFinal % 3 == 1) {
        buffer.write('.');
      }
    }
    return '$buffer-$dv';
  }

  /// Normaliza a "NNNNNNNN-K" (sin puntos) — el formato que espera el backend.
  static String normalizarConGuion(String rutCompleto) {
    final limpio = _limpiar(rutCompleto);
    if (limpio.length < 2) return rutCompleto;
    final cuerpo = limpio.substring(0, limpio.length - 1);
    final dv = limpio.substring(limpio.length - 1).toUpperCase();
    return '$cuerpo-$dv';
  }

  static String _limpiar(String rut) => rut.replaceAll(RegExp(r'[.\s]'), '').replaceAll('-', '');

  static String _calcularDv(String cuerpo) {
    var suma = 0;
    var multiplicador = 2;
    for (var i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    final resto = 11 - (suma % 11);
    if (resto == 11) return '0';
    if (resto == 10) return 'K';
    return resto.toString();
  }
}
