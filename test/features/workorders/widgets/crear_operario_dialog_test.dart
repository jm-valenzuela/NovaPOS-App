import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/widgets/crear_operario_dialog.dart';

import '../fakes/workorders_fakes.dart';

void main() {
  late FakeWorkOrdersRepository fake;

  Future<void> abrirDialogo(WidgetTester tester) async {
    fake = FakeWorkOrdersRepository()
      ..rolesARetornar = const [
        RolResumen(id: 'rol-cajero', nombre: 'Cajero'),
        RolResumen(id: 'rol-bodeguero', nombre: 'Bodeguero'),
      ];

    await tester.pumpWidget(ProviderScope(
      overrides: [workOrdersRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(context: context, builder: (_) => const CrearOperarioDialog()),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Guardar sin completar los campos muestra un error', (tester) async {
    await abrirDialogo(tester);

    await tester.tap(find.byKey(const Key('crearOperarioGuardar')));
    await tester.pump();

    expect(find.textContaining('Completa nombre, email, contraseña y Rol.'), findsOneWidget);
  });

  testWidgets('Con todos los campos llama a crearUsuario con el Rol elegido', (tester) async {
    await abrirDialogo(tester);

    await tester.enterText(find.byKey(const Key('crearOperarioNombre')), 'Pedro Rojas');
    await tester.enterText(find.byKey(const Key('crearOperarioEmail')), 'pedro@novapos-demo.cl');
    await tester.enterText(find.byKey(const Key('crearOperarioPassword')), 'Clave1234!');
    await tester.tap(find.byKey(const Key('crearOperarioRol')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bodeguero').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crearOperarioGuardar')));
    await tester.pump();
    await tester.pump();

    expect(fake.ultimoNombreOperario, 'Pedro Rojas');
    expect(fake.ultimoEmailOperario, 'pedro@novapos-demo.cl');
    expect(fake.ultimoRolIdOperario, 'rol-bodeguero');
  });
}
