import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/widgets/crear_variante_dialog.dart';

import '../fakes/catalog_admin_fakes.dart';

void main() {
  Future<FakeCatalogAdminRepository> pumpDialogo(WidgetTester tester) async {
    final fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const CrearVarianteDialog(productoId: 'producto-polera', nombreProducto: 'Polera Nike Dri-Fit'),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('No ofrece generar ni imprimir código de barras — la Variante todavía no existe', (tester) async {
    await pumpDialogo(tester);

    expect(find.byKey(const Key('generarCodigoBarrasVariante')), findsNothing);
    expect(find.byKey(const Key('imprimirEtiquetaConPrecioVariante')), findsNothing);
  });

  testWidgets('SKU vacío muestra error y no llama al repositorio', (tester) async {
    final fake = await pumpDialogo(tester);

    await tester.enterText(find.byKey(const Key('crearPrecioVariante')), '1000');
    await tester.tap(find.byKey(const Key('guardarCrearVariante')));
    await tester.pumpAndSettle();

    expect(find.textContaining('SKU es obligatorio'), findsOneWidget);
    expect(fake.ultimaCreacionVariante, isNull);
  });

  testWidgets('Completar SKU y precio crea la Variante y cierra el diálogo', (tester) async {
    final fake = await pumpDialogo(tester);

    await tester.enterText(find.byKey(const Key('crearSkuVariante')), 'POLNIKE-VERDE-M');
    await tester.enterText(find.byKey(const Key('crearPrecioVariante')), '21990');
    await tester.tap(find.byKey(const Key('guardarCrearVariante')));
    await tester.pumpAndSettle();

    expect(fake.ultimaCreacionVariante, isNotNull);
    expect(fake.ultimaCreacionVariante!['productoId'], 'producto-polera');
    expect(fake.ultimaCreacionVariante!['sku'], 'POLNIKE-VERDE-M');
    expect(fake.ultimaCreacionVariante!['precioVenta'], 21990.0);
    expect(fake.vecesListarProductosLlamado, greaterThanOrEqualTo(1));
    expect(find.byType(CrearVarianteDialog), findsNothing);
  });

  testWidgets('Un error del repositorio se muestra y el diálogo sigue abierto', (tester) async {
    final fake = await pumpDialogo(tester);
    fake.errorAforzar = 'El SKU ya está en uso.';

    await tester.enterText(find.byKey(const Key('crearSkuVariante')), 'POLNIKE-AZ-M');
    await tester.enterText(find.byKey(const Key('crearPrecioVariante')), '19990');
    await tester.tap(find.byKey(const Key('guardarCrearVariante')));
    await tester.pumpAndSettle();

    expect(find.textContaining('SKU ya está en uso'), findsOneWidget);
    expect(find.byType(CrearVarianteDialog), findsOneWidget);
  });
}
