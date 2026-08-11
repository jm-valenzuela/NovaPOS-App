import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/presentation/screens/productos_hub_screen.dart';

void main() {
  testWidgets('Muestra Productos, Marcas, Categorías y Ofertas para Imprimir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ProductosHubScreen())));

    expect(find.byKey(const Key('productosMantencionCard')), findsOneWidget);
    expect(find.byKey(const Key('productosMarcasCard')), findsOneWidget);
    expect(find.byKey(const Key('productosCategoriasCard')), findsOneWidget);
    expect(find.byKey(const Key('productosOfertasCard')), findsOneWidget);
    expect(find.text('Marcas'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Ofertas para Imprimir'), findsOneWidget);
  });
}
