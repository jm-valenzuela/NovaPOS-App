import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/core/providers/core_providers.dart';
import 'package:novapos_app/core/storage/token_storage.dart';
import 'package:novapos_app/main.dart';

import 'helpers/in_memory_secure_storage.dart';

/// Todos los widget tests sobreescriben tokenStorageProvider con
/// almacenamiento en memoria — el canal de plataforma real de
/// flutter_secure_storage no existe bajo `flutter test` y deja las
/// llamadas colgadas para siempre en vez de resolver o lanzar.
List<Override> _overridesDeTest() => [
      tokenStorageProvider.overrideWithValue(TokenStorage(InMemorySecureStorage())),
    ];

void main() {
  testWidgets('Sin sesión guardada, la app termina en la pantalla de Login', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _overridesDeTest(), child: const NovaPosApp()));
    // No se usa pumpAndSettle: el splash tiene un CircularProgressIndicator
    // indeterminado (animación continua) mientras se resuelve la sesión,
    // así que la app nunca "se asienta" del todo por sí sola.
    await tester.pump();
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Registra tu Empresa'), findsOneWidget);
  });

  testWidgets('Desde Login se puede navegar al Registro de Empresa', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _overridesDeTest(), child: const NovaPosApp()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('¿No tienes cuenta? Registra tu Empresa'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar Empresa'), findsWidgets);
    expect(find.text('Razón social'), findsOneWidget);
  });

  testWidgets('Login valida RUT, correo y contraseña antes de enviar', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _overridesDeTest(), child: const NovaPosApp()));
    await tester.pump();
    await tester.pump();

    // Los campos vienen precargados con la cuenta demo fija — se limpian acá
    // para probar la validación real de campos vacíos.
    await tester.enterText(find.byKey(const Key('loginRut')), '');
    await tester.enterText(find.byKey(const Key('loginEmail')), '');
    await tester.enterText(find.byKey(const Key('loginPassword')), '');

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu RUT'), findsOneWidget);
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });
}
