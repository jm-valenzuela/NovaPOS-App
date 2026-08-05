import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_admin.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/widgets/editar_variante_dialog.dart';

import '../fakes/catalog_admin_fakes.dart';

void main() {
  const varianteSinCodigo = VarianteAdmin(
    varianteProductoId: 'variante-sin-codigo',
    sku: 'SKU-SIN-CODIGO',
    codigoBarras: null,
    color: null,
    talla: null,
    precioVenta: 1500,
    unidadMedida: 0,
    ubicacionFisica: null,
    activa: true,
  );

  const varianteConCodigo = VarianteAdmin(
    varianteProductoId: 'variante-con-codigo',
    sku: 'SKU-CON-CODIGO',
    codigoBarras: '7801234567894',
    color: null,
    talla: null,
    precioVenta: 2500,
    unidadMedida: 0,
    ubicacionFisica: null,
    activa: true,
  );

  Future<FakeCatalogAdminRepository> pumpDialogo(WidgetTester tester, VarianteAdmin variante) async {
    final fake = FakeCatalogAdminRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => EditarVarianteDialog(variante: variante, nombreProducto: 'Producto de prueba'),
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

  testWidgets('Variante sin código muestra el botón de generar, no el de imprimir', (tester) async {
    await pumpDialogo(tester, varianteSinCodigo);

    expect(find.byKey(const Key('generarCodigoBarrasVariante')), findsOneWidget);
    expect(find.byKey(const Key('imprimirEtiquetaConPrecioVariante')), findsNothing);
    expect(find.byKey(const Key('imprimirEtiquetaSinPrecioVariante')), findsNothing);
  });

  testWidgets('Variante con código ya asignado muestra imprimir y la previsualización, no el de generar', (tester) async {
    await pumpDialogo(tester, varianteConCodigo);

    expect(find.byKey(const Key('generarCodigoBarrasVariante')), findsNothing);
    expect(find.byKey(const Key('imprimirEtiquetaConPrecioVariante')), findsOneWidget);
    expect(find.byKey(const Key('imprimirEtiquetaSinPrecioVariante')), findsOneWidget);
    expect(find.byKey(const Key('vistaPreviaEtiquetaBarcode')), findsOneWidget);
  });

  testWidgets('Generar código de barras lo pide al repositorio y muestra imprimir + previsualización', (tester) async {
    final fake = await pumpDialogo(tester, varianteSinCodigo);
    fake.codigoBarrasARetornar = '2099999999998';

    await tester.tap(find.byKey(const Key('generarCodigoBarrasVariante')));
    await tester.pumpAndSettle();

    expect(fake.codigosBarrasGenerados, contains('variante-sin-codigo'));
    expect(find.text('2099999999998'), findsOneWidget);
    expect(find.byKey(const Key('generarCodigoBarrasVariante')), findsNothing);
    expect(find.byKey(const Key('imprimirEtiquetaConPrecioVariante')), findsOneWidget);
    expect(find.byKey(const Key('imprimirEtiquetaSinPrecioVariante')), findsOneWidget);
    expect(find.byKey(const Key('vistaPreviaEtiquetaBarcode')), findsOneWidget);
  });

  testWidgets('Un error al generar se muestra y el botón de generar sigue disponible', (tester) async {
    final fake = await pumpDialogo(tester, varianteSinCodigo);
    fake.errorAforzar = 'La Variante ya tiene un código de barras asignado.';

    await tester.tap(find.byKey(const Key('generarCodigoBarrasVariante')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('generarCodigoBarrasVariante')), findsOneWidget);
    expect(find.byKey(const Key('imprimirEtiquetaConPrecioVariante')), findsNothing);
    expect(find.byKey(const Key('imprimirEtiquetaSinPrecioVariante')), findsNothing);
  });
}
