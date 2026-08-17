import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// `TextInputFormatter` que agrupa los dígitos ingresados con "." de miles
/// en vivo (ej. tipear "199980" se ve "199.980" mientras se escribe) —
/// mismo formato que `MonedaFormatter`, sin el símbolo "$". Solo dígitos:
/// el peso chileno no tiene decimales, así que cualquier otro carácter se
/// descarta en vez de intentar interpretarlo.
class FormateadorMiles extends TextInputFormatter {
  static final _formato = NumberFormat.decimalPattern('es_CL')..maximumFractionDigits = 0;

  /// Para setear un TextEditingController.text ya formateado (ej. al
  /// precargar un monto por código, no tipeado por el usuario) — mismo
  /// formato que produce este formatter mientras se escribe.
  static String formatear(num valor) => _formato.format(valor);

  /// Contraparte de [formatear] — recupera el valor numérico desde el
  /// texto ya formateado (quita los "." de miles).
  static double desformatear(String texto) {
    final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
    return digitos.isEmpty ? 0 : double.parse(digitos);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue();

    final formateado = _formato.format(int.parse(digitos));
    return TextEditingValue(text: formateado, selection: TextSelection.collapsed(offset: formateado.length));
  }
}
