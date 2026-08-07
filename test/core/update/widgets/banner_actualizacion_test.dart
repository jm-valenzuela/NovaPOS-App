import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/core/update/actualizacion_providers.dart';
import 'package:novapos_app/core/update/widgets/banner_actualizacion.dart';

/// No llama a recargarPagina() real (que en test corre bajo la variante
/// stub y no hace nada) — solo registra si se pidió, para poder
/// verificarlo sin depender de dart:html.
class _ControladorFalso extends ActualizacionController {
  bool recargarLlamado = false;

  @override
  void recargar() => recargarLlamado = true;
}

void main() {
  testWidgets('Sin actualización disponible, no muestra la franja', (tester) async {
    final controlador = _ControladorFalso();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [actualizacionDisponibleProvider.overrideWith((ref) => controlador)],
        child: const MaterialApp(home: BannerActualizacion(child: Text('Contenido'))),
      ),
    );

    expect(find.text('Contenido'), findsOneWidget);
    expect(find.text('Hay una nueva versión de NovaPOS disponible.'), findsNothing);
  });

  testWidgets('Con actualización disponible, muestra la franja y el botón recarga', (tester) async {
    final controlador = _ControladorFalso();
    controlador.state = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [actualizacionDisponibleProvider.overrideWith((ref) => controlador)],
        child: const MaterialApp(home: BannerActualizacion(child: Text('Contenido'))),
      ),
    );

    expect(find.text('Contenido'), findsOneWidget);
    expect(find.text('Hay una nueva versión de NovaPOS disponible.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('actualizacionRecargar')));

    expect(controlador.recargarLlamado, isTrue);
  });
}
