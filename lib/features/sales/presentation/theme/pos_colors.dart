import 'package:flutter/material.dart';

/// Paleta del Punto de Venta — marco oscuro (header + panel de carrito)
/// envolviendo un área de trabajo clara (buscador + grilla de productos),
/// mismo patrón visual que un POS físico de caja registradora.
class PosColors {
  PosColors._();

  static const navy = Color(0xFF101F35);
  static const navyLight = Color(0xFF1B2E4A);
  static const navyBorder = Color(0xFF2A3F5F);
  static const workspace = Color(0xFFF6F4EF);
  static const cardBorder = Color(0xFFE4E0D6);
  static const accent = Color(0xFFF2A93B);
  static const accentDark = Color(0xFFC97F1E);
  static const textMuted = Color(0xFF8A96AC);

  /// Precio normal tachado cuando hay una Oferta vigente — amarillo en vez
  /// del gris muted genérico, para que el "antes" resalte junto al precio
  /// de oferta (a pedido explícito).
  static const precioTachado = Color(0xFFD9B31C);
  static const stockOk = Color(0xFF2E7D46);
  static const stockOkBg = Color(0xFFE1F0E5);
  static const stockLow = Color(0xFFB9791A);
  static const stockLowBg = Color(0xFFFBEBD3);
  static const stockOut = Color(0xFFC0392B);
  static const stockOutBg = Color(0xFFF9E1DE);
}
