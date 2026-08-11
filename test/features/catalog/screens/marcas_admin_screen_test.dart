import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/screens/marcas_admin_screen.dart';

import '../fakes/catalog_admin_fakes.dart';

void main() {
  late FakeCatalogAdminRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: MarcasAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra las Marcas existentes', (tester) async {
    fake = FakeCatalogAdminRepository()..marcas = [const Marca(id: 'marca-1', nombre: 'Nike', activa: true)];
    await pumpPantalla(tester);

    expect(find.text('Nike'), findsOneWidget);
  });

  testWidgets('Sin Marcas muestra el mensaje vacío', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    expect(find.text('Sin Marcas creadas todavía.'), findsOneWidget);
  });

  testWidgets('Crear una Marca nueva la agrega a la lista', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('marcasNuevaBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoNombreCampo')), 'Adidas');
    await tester.tap(find.byKey(const Key('nuevoNombreGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Adidas'), findsOneWidget);
  });

  testWidgets('Nombre vacío muestra un error y no llama al repositorio', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('marcasNuevaBoton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nuevoNombreGuardar')));
    await tester.pump();

    expect(find.text('El nombre es obligatorio.'), findsOneWidget);
    expect(fake.marcas, isEmpty);
  });
}
