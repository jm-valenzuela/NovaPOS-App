import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:novapos_app/main.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  Future<void> pumpApp(WidgetTester tester) async {
    fakeRepository = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      child: const NovaPosApp(),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Login válido llama a AuthRepository.login y navega al Home', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('loginRut')), '12.345.678-5');
    await tester.enterText(find.byKey(const Key('loginEmail')), 'admin@apptest.cl');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'TestPass123!');

    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(fakeRepository.vecesLoginLlamado, 1);
    expect(fakeRepository.ultimoRutLogin, '12345678-5', reason: 'se envía normalizado sin puntos, con guión');
    expect(fakeRepository.ultimoEmailLogin, 'admin@apptest.cl');
    expect(fakeRepository.ultimoPasswordLogin, 'TestPass123!');
    expect(find.text('Punto de Venta'), findsOneWidget);
    expect(find.text('Ana Pérez · Minimarket Don José SpA'), findsOneWidget, reason: 'Home muestra con qué Usuario y Empresa se inició sesión');
  });

  testWidgets('Credenciales rechazadas por el backend muestran el error y no navegan', (tester) async {
    await pumpApp(tester);
    fakeRepository.errorAforzar = 'RUT, correo o contraseña incorrectos.';

    await tester.enterText(find.byKey(const Key('loginRut')), '12.345.678-5');
    await tester.enterText(find.byKey(const Key('loginEmail')), 'admin@apptest.cl');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'ClaveIncorrecta');

    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('RUT, correo o contraseña incorrectos'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget, reason: 'sigue en Login, no navegó al Home');
  });

  testWidgets('Con una sesión ya activa, la app entra directo al Home sin mostrar Login', (tester) async {
    fakeRepository = FakeAuthRepository()..sesionActiva = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      child: const NovaPosApp(),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Punto de Venta'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);
    expect(
      find.text('Ana Pérez · Minimarket Don José SpA'),
      findsOneWidget,
      reason: 'la sesión restaurada también trae quién es el Usuario y la Empresa, no solo el login fresco',
    );
  });
}
