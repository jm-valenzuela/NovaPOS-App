import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/features/catalog/domain/catalog_admin_repository.dart';
import 'package:novapos_app/features/catalog/domain/models/clasificacion.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_admin_providers.dart';
import 'package:novapos_app/features/catalog/presentation/providers/catalog_form_providers.dart';

import '../fakes/catalog_admin_fakes.dart';

void main() {
  late FakeCatalogAdminRepository fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeCatalogAdminRepository()
      ..departamentos = [const Departamento(id: 'depto-1', nombre: 'Vestuario', activo: true)]
      ..marcas = [const Marca(id: 'marca-1', nombre: 'Nike', activa: true)];

    container = ProviderContainer(overrides: [
      catalogAdminRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);
    // catalogFormProvider es autoDispose — sin un listener activo, Riverpod
    // lo destruye entre lecturas y cada container.read() devolvería una
    // instancia nueva, perdiendo el estado acumulado dentro del test.
    container.listen(catalogFormProvider, (previo, actual) {}, fireImmediately: true);
  });

  Future<void> esperarMicrotareas() => Future<void>.delayed(Duration.zero);

  test('Al crear el controller, carga Departamentos y Marcas', () async {
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();

    expect(container.read(catalogFormProvider).departamentos, hasLength(1));
    expect(container.read(catalogFormProvider).marcas, hasLength(1));
    expect(notifier, isNotNull);
  });

  test('Seleccionar un Departamento carga sus SubDepartamentos', () async {
    fake.subDepartamentos = [const SubDepartamento(id: 'subdepto-1', departamentoId: 'depto-1', nombre: 'Poleras', activo: true)];
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();

    await notifier.seleccionarDepartamento('depto-1');

    expect(container.read(catalogFormProvider).subDepartamentos, hasLength(1));
    expect(fake.ultimoDepartamentoIdPedido, 'depto-1');
  });

  test('Seleccionar un nuevo Departamento limpia SubDepartamento/Clase/Subclase ya elegidos', () async {
    fake.subDepartamentos = [const SubDepartamento(id: 'subdepto-1', departamentoId: 'depto-1', nombre: 'Poleras', activo: true)];
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();
    await notifier.seleccionarDepartamento('depto-1');
    await notifier.seleccionarSubDepartamento('subdepto-1');

    expect(container.read(catalogFormProvider).subDepartamentoId, 'subdepto-1');

    await notifier.seleccionarDepartamento('depto-2');

    expect(container.read(catalogFormProvider).subDepartamentoId, isNull);
    expect(container.read(catalogFormProvider).subDepartamentos, isEmpty);
  });

  test('Crear un Departamento nuevo lo agrega a la lista y lo selecciona', () async {
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();

    await notifier.crearDepartamento('Hogar');

    final estado = container.read(catalogFormProvider);
    expect(estado.departamentos.any((d) => d.nombre == 'Hogar'), isTrue);
    expect(estado.departamentoId, isNotNull);
  });

  test('crearProducto no hace nada si falta Subclase o Marca', () async {
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();

    await notifier.crearProducto(nombre: 'Polera', sku: 'SKU-1', precioVenta: 1000, unidadMedida: 0);

    expect(container.read(catalogFormProvider).resultado, isNull);
  });

  test('crearProducto con clasificación completa llama al repositorio y guarda el resultado', () async {
    fake.resultadoCrear = const CrearProductoResultado(productoId: 'p-1', varianteProductoId: 'v-1');
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();
    notifier.seleccionarMarca('marca-1');
    // Simula haber llegado a una Subclase vía la cascada.
    notifier.inicializarClasificacionExistente(subclaseId: 'subclase-1', marcaId: 'marca-1');

    await notifier.crearProducto(nombre: 'Polera', sku: 'SKU-1', precioVenta: 1000, unidadMedida: 0);

    final estado = container.read(catalogFormProvider);
    expect(estado.resultado?.productoId, 'p-1');
    expect(estado.guardando, isFalse);
  });

  test('inicializarClasificacionExistente deja clasificacionCompleta en true sin tocar la cascada', () async {
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();

    notifier.inicializarClasificacionExistente(subclaseId: 'subclase-9', marcaId: 'marca-9');

    expect(container.read(catalogFormProvider).clasificacionCompleta, isTrue);
  });

  test('actualizarProducto propaga el error del repositorio y devuelve false', () async {
    fake.errorAforzar = 'No se pudo conectar con el servidor.';
    final notifier = container.read(catalogFormProvider.notifier);
    await esperarMicrotareas();
    notifier.inicializarClasificacionExistente(subclaseId: 'subclase-1', marcaId: 'marca-1');

    final ok = await notifier.actualizarProducto(productoId: 'p-1', nombre: 'Nuevo nombre');

    expect(ok, isFalse);
    expect(container.read(catalogFormProvider).error, contains('No se pudo conectar'));
  });
}
