import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_admin.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/screens/productos_oferta_screen.dart';

import '../fakes/catalog_admin_fakes.dart';

ProductoAdmin _productoConOferta({required String id, required bool ofertaVigente}) {
  final hoy = DateTime.now();
  return ProductoAdmin(
    productoId: 'producto-$id',
    nombre: 'Producto $id',
    descripcion: null,
    departamentoId: 'depto-1',
    departamentoNombre: 'Depto',
    subclaseId: 'subclase-1',
    subclaseNombre: 'Subclase',
    marcaId: 'marca-1',
    marcaNombre: 'Marca',
    activo: true,
    variantes: [
      VarianteAdmin(
        varianteProductoId: 'variante-$id',
        sku: 'SKU-$id',
        codigoBarras: null,
        color: null,
        talla: null,
        precioVenta: 10000,
        unidadMedida: 0,
        ubicacionFisica: null,
        activa: true,
        precioOferta: 7990,
        ofertaDesde: ofertaVigente ? hoy.subtract(const Duration(days: 1)) : hoy.add(const Duration(days: 5)),
        ofertaHasta: ofertaVigente ? hoy.add(const Duration(days: 1)) : hoy.add(const Duration(days: 10)),
      ),
    ],
  );
}

void main() {
  late FakeCatalogAdminRepository fake;

  Future<void> pumpPantalla(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogAdminRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ProductosOfertaScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Muestra solo las Variantes con oferta vigente hoy', (tester) async {
    fake = FakeCatalogAdminRepository()
      ..productos = [
        _productoConOferta(id: 'vigente', ofertaVigente: true),
        _productoConOferta(id: 'futura', ofertaVigente: false),
      ];
    await pumpPantalla(tester);

    expect(find.text('Producto vigente'), findsOneWidget);
    expect(find.text('Producto futura'), findsNothing);
    expect(find.byKey(const Key('ofertasImprimirBoton')), findsOneWidget);
  });

  testWidgets('Sin ofertas vigentes no muestra el botón de imprimir', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [_productoConOferta(id: 'futura', ofertaVigente: false)];
    await pumpPantalla(tester);

    expect(find.text('No hay Variantes con oferta vigente hoy.'), findsOneWidget);
    expect(find.byKey(const Key('ofertasImprimirBoton')), findsNothing);
  });
}
