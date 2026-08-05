import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/screens/catalog_form_screen.dart';
import 'package:novapos_app/features/catalog/presentation/screens/productos_admin_screen.dart';

import '../fakes/catalog_admin_fakes.dart';

void main() {
  late FakeCatalogAdminRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ProductosAdminScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra los Productos con sus Variantes al expandir', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await pumpPantalla(tester);

    expect(find.text('Polera Nike Dri-Fit'), findsOneWidget);
    expect(find.text('Manga Corta · Nike'), findsOneWidget);

    await tester.tap(find.byKey(const Key('catalogoProducto_producto-polera')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('catalogoVariante_variante-polera-az-m')), findsOneWidget);
  });

  testWidgets('Lista vacía muestra el mensaje correspondiente', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    expect(find.text('No hay Productos creados todavía.'), findsOneWidget);
  });

  testWidgets('Alternar el switch de un Producto activo lo desactiva y recarga', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('catalogoProductoActivo_producto-polera')));
    await tester.pump();
    await tester.pump();

    expect(fake.productosDesactivados, contains('producto-polera'));
    expect(fake.vecesListarProductosLlamado, greaterThanOrEqualTo(2));
  });

  testWidgets('Alternar el switch de una Variante activa la desactiva y recarga', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await pumpPantalla(tester);
    await tester.tap(find.byKey(const Key('catalogoProducto_producto-polera')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('catalogoVarianteActiva_variante-polera-az-m')));
    await tester.pump();
    await tester.pump();

    expect(fake.variantesDesactivadas, contains('variante-polera-az-m'));
  });

  testWidgets('El botón + navega a la pantalla de creación de Producto', (tester) async {
    fake = FakeCatalogAdminRepository();
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('catalogoNuevoProducto')));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogFormScreen), findsOneWidget);
  });

  testWidgets('El ícono de editar Producto abre el diálogo de edición', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await pumpPantalla(tester);

    await tester.tap(find.byKey(const Key('catalogoEditarProducto_producto-polera')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Producto'), findsOneWidget);
  });

  testWidgets('Un error al cargar se muestra en un SnackBar', (tester) async {
    fake = FakeCatalogAdminRepository()..errorAforzar = 'No se pudo conectar con el servidor.';
    await pumpPantalla(tester);

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
  });

  testWidgets('Buscar por nombre filtra la lista en memoria', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin, productoZapatillaAdmin];
    await pumpPantalla(tester);

    expect(find.text('Polera Nike Dri-Fit'), findsOneWidget);
    expect(find.text('Zapatilla Adidas Running'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('catalogoBusqueda')), 'zapatilla');
    await tester.pump();

    expect(find.text('Polera Nike Dri-Fit'), findsNothing);
    expect(find.text('Zapatilla Adidas Running'), findsOneWidget);
    // No se vuelve a llamar al backend — es un filtro local.
    expect(fake.vecesListarProductosLlamado, 1);
  });

  testWidgets('Buscar por SKU de una Variante también filtra', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin, productoZapatillaAdmin];
    await pumpPantalla(tester);

    await tester.enterText(find.byKey(const Key('catalogoBusqueda')), 'POLNIKE');
    await tester.pump();

    expect(find.text('Polera Nike Dri-Fit'), findsOneWidget);
    expect(find.text('Zapatilla Adidas Running'), findsNothing);
  });

  testWidgets('Sin resultados para el texto buscado muestra un mensaje', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin];
    await pumpPantalla(tester);

    await tester.enterText(find.byKey(const Key('catalogoBusqueda')), 'inexistente');
    await tester.pump();

    expect(find.textContaining('Sin resultados'), findsOneWidget);
  });

  testWidgets('Limpiar la búsqueda vuelve a mostrar todos los Productos', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [productoPoleraAdmin, productoZapatillaAdmin];
    await pumpPantalla(tester);

    await tester.enterText(find.byKey(const Key('catalogoBusqueda')), 'zapatilla');
    await tester.pump();
    expect(find.text('Polera Nike Dri-Fit'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('Polera Nike Dri-Fit'), findsOneWidget);
    expect(find.text('Zapatilla Adidas Running'), findsOneWidget);
  });
}
