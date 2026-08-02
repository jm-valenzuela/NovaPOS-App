import 'package:intl/intl.dart';

/// Peso chileno — sin decimales, punto como separador de miles, símbolo
/// antes del monto (ej. "$15.990"). NumberFormat.currency con locale
/// 'es_CL' pone el símbolo DESPUÉS del número ("15.990 $") — no es la
/// convención real de precios en Chile, así que se arma el símbolo a
/// mano sobre un NumberFormat de solo agrupación de miles.
class MonedaFormatter {
  MonedaFormatter._();

  static final _formato = NumberFormat.decimalPattern('es_CL')..maximumFractionDigits = 0;

  static String formatear(num monto) => r'$' + _formato.format(monto);
}
