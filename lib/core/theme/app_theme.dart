import 'package:flutter/material.dart';

/// Tema único de la app — un solo lugar para ajustar colores/tipografía
/// más adelante en vez de repetir estilos pantalla por pantalla.
class AppTheme {
  AppTheme._();

  static const Color colorPrimario = Color(0xFF0F6E5E);

  static ThemeData get claro {
    final colorScheme = ColorScheme.fromSeed(seedColor: colorPrimario);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
