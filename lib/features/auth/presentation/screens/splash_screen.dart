import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Se muestra brevemente mientras AuthController resuelve si hay una
/// sesión guardada (lectura de almacenamiento seguro, es async) — el
/// GoRouter redirige desde acá apenas el estado deja de ser "desconocido".
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/branding/novapos_icon.svg', width: 72, height: 72),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
