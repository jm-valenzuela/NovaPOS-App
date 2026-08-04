/// Etiquetas legibles para la promoción por grupo (ej. "2x1", "6x5",
/// "2do al 40% dto.") — un único mecanismo parametrizado
/// (cantidadPorGrupo + porcentajeDescuentoUnidad) cubre cualquier
/// combinación NxM, así que la etiqueta se deriva de esos 2 números en
/// vez de guardarse aparte. Usado tanto en el formulario de Catálogo
/// (dropdown de presets) como en la UI del POS (tarjeta y carrito).
class PromocionGrupo {
  PromocionGrupo._();

  static String etiqueta(int cantidadPorGrupo, double porcentajeDescuentoUnidad) {
    if (porcentajeDescuentoUnidad == 100) {
      return '${cantidadPorGrupo}x${cantidadPorGrupo - 1}';
    }
    if (cantidadPorGrupo == 2) {
      return '2do al ${_formatearPorcentaje(porcentajeDescuentoUnidad)}% dto.';
    }
    return 'Cada $cantidadPorGrupo uds., -${_formatearPorcentaje(porcentajeDescuentoUnidad)}% en la última';
  }

  static String _formatearPorcentaje(double porcentaje) =>
      porcentaje.truncateToDouble() == porcentaje ? porcentaje.toInt().toString() : porcentaje.toString();
}
