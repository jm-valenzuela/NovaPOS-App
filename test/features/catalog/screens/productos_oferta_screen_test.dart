import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/models/producto_admin.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/screens/productos_oferta_screen.dart';

import '../fakes/catalog_admin_fakes.dart';

ProductoAdmin _base({
  required String id,
  bool ofertaVigente = false,
  bool ofertaFutura = false,
  int? cantidadMinimaDescuentoVolumen,
  double? porcentajeDescuentoVolumen,
  int? cantidadPorGrupoPromocion,
  double? porcentajeDescuentoUnidadPromocion,
}) {
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
        cantidadMinimaDescuentoVolumen: cantidadMinimaDescuentoVolumen,
        porcentajeDescuentoVolumen: porcentajeDescuentoVolumen,
        cantidadPorGrupoPromocion: cantidadPorGrupoPromocion,
        porcentajeDescuentoUnidadPromocion: porcentajeDescuentoUnidadPromocion,
        precioOferta: (ofertaVigente || ofertaFutura) ? 7990 : null,
        ofertaDesde: ofertaVigente
            ? hoy.subtract(const Duration(days: 1))
            : ofertaFutura
                ? hoy.add(const Duration(days: 5))
                : null,
        ofertaHasta: ofertaVigente
            ? hoy.add(const Duration(days: 1))
            : ofertaFutura
                ? hoy.add(const Duration(days: 10))
                : null,
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

  testWidgets('Muestra Variantes con precio de oferta vigente', (tester) async {
    fake = FakeCatalogAdminRepository()
      ..productos = [_base(id: 'vigente', ofertaVigente: true), _base(id: 'futura', ofertaFutura: true)];
    await pumpPantalla(tester);

    expect(find.text('Producto vigente'), findsOneWidget);
    expect(find.text('Producto futura'), findsNothing);
    expect(find.byKey(const Key('ofertasImprimirBoton')), findsOneWidget);
  });

  testWidgets('Muestra Variantes con descuento por volumen, con su etiqueta', (tester) async {
    fake = FakeCatalogAdminRepository()
      ..productos = [_base(id: 'volumen', cantidadMinimaDescuentoVolumen: 15, porcentajeDescuentoVolumen: 5)];
    await pumpPantalla(tester);

    expect(find.text('Producto volumen'), findsOneWidget);
    expect(find.text('Desde 15 uds. -5%'), findsOneWidget);
  });

  testWidgets('Muestra Variantes con promoción por grupo (2x1)', (tester) async {
    fake = FakeCatalogAdminRepository()
      ..productos = [_base(id: 'grupo', cantidadPorGrupoPromocion: 2, porcentajeDescuentoUnidadPromocion: 100)];
    await pumpPantalla(tester);

    expect(find.text('Producto grupo'), findsOneWidget);
    expect(find.text('2x1'), findsOneWidget);
  });

  testWidgets('Sin ofertas ni promociones vigentes no muestra el botón de imprimir', (tester) async {
    fake = FakeCatalogAdminRepository()..productos = [_base(id: 'futura', ofertaFutura: true)];
    await pumpPantalla(tester);

    expect(find.text('No hay Variantes con ofertas o promociones vigentes hoy.'), findsOneWidget);
    expect(find.byKey(const Key('ofertasImprimirBoton')), findsNothing);
  });
}
