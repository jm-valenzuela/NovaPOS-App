import 'package:flutter/material.dart';

/// Se muestra brevemente mientras AuthController resuelve si hay una
/// sesión guardada (lectura de almacenamiento seguro, es async) — el
/// GoRouter redirige desde acá apenas el estado deja de ser "desconocido".
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
