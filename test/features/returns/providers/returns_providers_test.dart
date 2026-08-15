import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novapos_app/features/returns/domain/models/linea_devolucion_input.dart';
import 'package:novapos_app/features/returns/presentation/providers/returns_providers.dart';

import '../fakes/returns_fakes.dart';

void main() {
  late FakeReturnsRepository fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeReturnsRepository();
    container = ProviderContainer(overrides: [returnsRepositoryProvider.overrideWithValue(fake)]);
  });

  tearDown(() => container.dispose());

  group('RegistrarDevolucionController', () {
    test('registrar exitoso devuelve el Id y propaga los parámetros al repositorio', () async {
      fake.idADevolver = 'nota-123';
      final controller = container.read(registrarDevolucionProvider.notifier);

      final id = await controller.registrar(
        ventaOrigenId: 'venta-1',
        clienteId: 'cliente-1',
        lineas: const [LineaDevolucionInput(varianteProductoId: 'variante-1', cantidad: 2)],
        motivo: 'Producto defectuoso',
        reembolsarEnEfectivo: true,
        sesionCajaId: 'sesion-1',
      );

      expect(id, 'nota-123');
      expect(fake.ultimaVentaOrigenIdRegistrada, 'venta-1');
      expect(fake.ultimoClienteIdRegistrado, 'cliente-1');
      expect(fake.ultimoReembolsarEnEfectivo, isTrue);
      expect(fake.ultimaSesionCajaIdRegistrada, 'sesion-1');
      expect(container.read(registrarDevolucionProvider).registrando, isFalse);
      expect(container.read(registrarDevolucionProvider).error, isNull);
    });

    test('registrar con error del repositorio deja el error en el estado y devuelve null', () async {
      fake.errorAforzar = 'Ya se devolvieron 3 de 3 unidades';
      final controller = container.read(registrarDevolucionProvider.notifier);

      final id = await controller.registrar(
        ventaOrigenId: 'venta-1',
        clienteId: 'cliente-1',
        lineas: const [LineaDevolucionInput(varianteProductoId: 'variante-1', cantidad: 1)],
        motivo: 'Motivo',
        reembolsarEnEfectivo: false,
      );

      expect(id, isNull);
      expect(container.read(registrarDevolucionProvider).error, contains('Ya se devolvieron'));
      expect(container.read(registrarDevolucionProvider).registrando, isFalse);
    });
  });

  group('notasDisponiblesProvider', () {
    test('expone las Notas Disponibles que retorna el repositorio', () async {
      fake.notasARetornar = [];
      final resultado = await container.read(notasDisponiblesProvider('cliente-1').future);
      expect(resultado, isEmpty);
    });
  });
}
