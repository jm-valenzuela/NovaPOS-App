import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/screens/categorias_admin_screen.dart';

import '../fakes/catalog_admin_fakes.dart';

const _vestuario = Departamento(id: 'depto-vestuario', nombre: 'Vestuario', activo: true);
const _poleras = SubDepartamento(id: 'subdepto-poleras', departamentoId: 'depto-vestuario', nombre: 'Poleras', activo: true);

void main() {
  late FakeCatalogAdminRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: CategoriasAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra los Departamentos existentes', (tester) async {
    fake = FakeCatalogAdminRepository()..departamentos = [_vestuario];
    await pumpPantalla(tester);

    expect(find.text('Vestuario'), findsOneWidget);
  });

  testWidgets('Expandir un Departamento muestra sus SubDepartamentos', (tester) async {
    fake = FakeCatalogAdminRepository()
      ..departamentos = [_vestuario]
      ..subDepartamentos = [_poleras];
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('categoriaDepartamento_depto-vestuario')));
    await tester.pumpAndSettle();

    expect(find.text('Poleras'), findsOneWidget);
  });

  testWidgets('Crear un nuevo Departamento lo agrega a la lista', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('categoriasNuevoDepartamentoBoton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoNombreCampo')), 'Calzado');
    await tester.tap(find.byKey(const Key('nuevoNombreGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Calzado'), findsOneWidget);
  });

  testWidgets('Crear un SubDepartamento dentro de un Departamento expandido', (tester) async {
    fake = FakeCatalogAdminRepository()..departamentos = [_vestuario];
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('categoriaDepartamento_depto-vestuario')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('categoriaNuevoSubDepartamento_depto-vestuario')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nuevoNombreCampo')), 'Pantalones');
    await tester.tap(find.byKey(const Key('nuevoNombreGuardar')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalones'), findsOneWidget);
    expect(fake.ultimoDepartamentoIdPedido, 'depto-vestuario');
  });
}
