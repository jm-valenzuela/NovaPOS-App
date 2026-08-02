import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/auth/domain/models/registrar_empresa_result.dart';
import 'package:novapos_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:novapos_app/main.dart';

import '../fakes/fake_auth_repository.dart';

/// Ejercita el flujo real de Registro de Empresa (llenar el formulario
/// completo + enviar) contra un AuthRepository fake — sin Dio/HTTP real,
/// pero pasando por Form.validate(), el Controller de Riverpod y el
/// diálogo de éxito exactamente como en producción.
void main() {
  late FakeAuthRepository fakeRepository;

  Future<void> pumpAppYNavegarARegistro(WidgetTester tester) async {
    fakeRepository = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      child: const NovaPosApp(),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('¿No tienes cuenta? Registra tu Empresa'));
    await tester.pumpAndSettle();
  }

  /// El botón queda debajo del borde inferior del formulario largo — hay
  /// que desplazarlo a la vista antes de tocarlo, si no el tap no impacta
  /// ningún widget (hit-test fuera del árbol de render visible).
  Future<void> tocarEnviar(WidgetTester tester) async {
    // Deja asentar primero cualquier auto-scroll pendiente de un enterText
    // anterior (Flutter desplaza el campo recién enfocado a la vista) —
    // si no, ese scroll en vuelo compite con el de ensureVisible de acá abajo.
    await tester.pumpAndSettle();
    final boton = find.byKey(const Key('submitRegistroEmpresa'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
  }

  Future<void> llenarFormularioValido(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('razonSocial')), 'Comercial App Test SPA');
    await tester.enterText(find.byKey(const Key('rutEmpresa')), '91.345.671-8');
    await tester.enterText(find.byKey(const Key('giroComercial')), 'Comercio y venta al detalle');
    await tester.enterText(find.byKey(const Key('emailEmpresa')), 'contacto@apptest.cl');
    // Modalidad y Nombre de Sucursal quedan en sus valores por defecto (SaaS / Casa Matriz).
    await tester.enterText(find.byKey(const Key('nombreAdministrador')), 'Admin App Test');
    await tester.enterText(find.byKey(const Key('emailAdministrador')), 'admin@apptest.cl');
    await tester.enterText(find.byKey(const Key('password')), 'TestPass123!');
    await tester.enterText(find.byKey(const Key('passwordConfirmar')), 'TestPass123!');
  }

  testWidgets('Enviar el formulario válido llama a AuthRepository.registrarEmpresa con los datos correctos', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    await llenarFormularioValido(tester);

    await tocarEnviar(tester);
    await tester.pumpAndSettle();

    expect(fakeRepository.vecesRegistrarLlamado, 1);
    expect(fakeRepository.ultimaRazonSocial, 'Comercial App Test SPA');
    expect(fakeRepository.ultimoRutEmpresa, '91345671-8', reason: 'se envía normalizado sin puntos, con guión');
    expect(fakeRepository.ultimoGiroComercial, 'Comercio y venta al detalle');
    expect(fakeRepository.ultimoEmailEmpresa, 'contacto@apptest.cl');
    expect(fakeRepository.ultimaModalidad, ModalidadEmpresa.saaS);
    expect(fakeRepository.ultimoNombreSucursal, 'Casa Matriz');
    expect(fakeRepository.ultimoNombreAdministrador, 'Admin App Test');
    expect(fakeRepository.ultimoEmailAdministrador, 'admin@apptest.cl');
    expect(fakeRepository.ultimoPasswordAdministrador, 'TestPass123!');
  });

  testWidgets('Al registrar con éxito muestra el diálogo de confirmación', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    await llenarFormularioValido(tester);

    await tocarEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Empresa registrada'), findsOneWidget);
    expect(find.text('Ir a Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Confirmar el diálogo de éxito vuelve a la pantalla de Login', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    await llenarFormularioValido(tester);

    await tocarEnviar(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ir a Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(fakeRepository.vecesLoginLlamado, 0, reason: 'registrar la Empresa NO deja sesión iniciada, ver AuthRepositoryImpl');
  });

  testWidgets('RUT inválido bloquea el envío y no llama al repositorio', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    await llenarFormularioValido(tester);
    await tester.enterText(find.byKey(const Key('rutEmpresa')), '12345678-9'); // DV incorrecto, fixture conocido

    await tocarEnviar(tester);
    await tester.pump();

    expect(find.text('RUT inválido'), findsOneWidget);
    expect(fakeRepository.vecesRegistrarLlamado, 0);
  });

  testWidgets('Contraseñas que no coinciden bloquean el envío', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    await llenarFormularioValido(tester);
    await tester.enterText(find.byKey(const Key('passwordConfirmar')), 'OtraClave456!');

    await tocarEnviar(tester);
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(fakeRepository.vecesRegistrarLlamado, 0);
  });

  testWidgets('Un error del backend se muestra en un SnackBar y no navega', (tester) async {
    await pumpAppYNavegarARegistro(tester);
    fakeRepository.errorAforzar = "Ya existe una Empresa con el RUT '91345671-8'.";
    await llenarFormularioValido(tester);

    await tocarEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ya existe una Empresa'), findsOneWidget);
    expect(find.text('Empresa registrada'), findsNothing);
  });
}
