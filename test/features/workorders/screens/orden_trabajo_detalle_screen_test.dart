import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novapos_app/core/utils/moneda_formatter.dart';
import 'package:novapos_app/features/auth/domain/models/sesion_usuario.dart';
import 'package:novapos_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:novapos_app/features/sales/domain/models/venta_detalle.dart';
import 'package:novapos_app/features/sales/domain/models/venta_enums.dart';
import 'package:novapos_app/features/sales/presentation/providers/pos_providers.dart' show salesRepositoryProvider;
import 'package:novapos_app/features/workorders/domain/models/orden_trabajo.dart';
import 'package:novapos_app/features/workorders/presentation/providers/workorders_providers.dart';
import 'package:novapos_app/features/workorders/presentation/screens/orden_trabajo_detalle_screen.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../../sales/fakes/pos_fakes.dart';
import '../fakes/workorders_fakes.dart';

const _lineaTrabajo = LineaItemOrdenTrabajo(
  id: 'linea-1',
  tipo: TipoLineaOrdenTrabajo.trabajo,
  descripcion: 'Cambio de amortiguadores',
  varianteProductoId: null,
  cantidad: null,
  monto: 80000,
);

const _itemPendiente = ItemOrdenTrabajoDetalle(
  id: 'item-1',
  descripcion: 'Ruido en tren delantero',
  estado: EstadoItemOrdenTrabajo.pendienteEvaluacion,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [],
  montoTotal: null,
);

const _itemCotizado = ItemOrdenTrabajoDetalle(
  id: 'item-2',
  descripcion: 'Cambio de aceite',
  estado: EstadoItemOrdenTrabajo.cotizado,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [_lineaTrabajo],
  montoTotal: 80000,
);

const _itemAprobado = ItemOrdenTrabajoDetalle(
  id: 'item-3',
  descripcion: 'Cambio de aceite',
  estado: EstadoItemOrdenTrabajo.aprobado,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [_lineaTrabajo],
  montoTotal: 80000,
);

const _itemEnTrabajo = ItemOrdenTrabajoDetalle(
  id: 'item-4',
  descripcion: 'Cambio de aceite',
  estado: EstadoItemOrdenTrabajo.enTrabajo,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [_lineaTrabajo],
  montoTotal: 80000,
);

const _itemRechazado = ItemOrdenTrabajoDetalle(
  id: 'item-5',
  descripcion: 'Suspensión',
  estado: EstadoItemOrdenTrabajo.rechazado,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: 'Muy caro',
  lineas: [_lineaTrabajo],
  montoTotal: 80000,
);

const _itemTerminado = ItemOrdenTrabajoDetalle(
  id: 'item-6',
  descripcion: 'Cambio de aceite',
  estado: EstadoItemOrdenTrabajo.terminado,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [_lineaTrabajo],
  montoTotal: 25000,
);

final _itemConHistorial = ItemOrdenTrabajoDetalle(
  id: 'item-7',
  descripcion: 'Cambio de aceite',
  estado: EstadoItemOrdenTrabajo.aprobado,
  observacion: null,
  asignadoAUsuarioId: null,
  asignadoANombre: null,
  motivoRechazo: null,
  lineas: [_lineaTrabajo],
  montoTotal: 80000,
  historial: [
    EventoHistorialItem(tipo: TipoEventoItemOrdenTrabajo.creado, fecha: DateTime.utc(2026, 8, 17, 10), usuarioNombre: 'Admin Demo', detalle: null),
    EventoHistorialItem(tipo: TipoEventoItemOrdenTrabajo.aprobado, fecha: DateTime.utc(2026, 8, 17, 11), usuarioNombre: 'Admin Demo', detalle: null),
  ],
);

OrdenTrabajoDetalle _orden({
  required EstadoOrdenTrabajo estado,
  List<ItemOrdenTrabajoDetalle> items = const [_itemCotizado],
  double? montoCotizado,
  double? montoAprobado,
  List<AnticipoOrdenTrabajoDetalle> anticipos = const [],
  double? montoAnticipado,
  double? saldoPendiente,
  String? ventaId,
}) {
  return OrdenTrabajoDetalle(
    id: 'ot-1',
    numero: 'OT-20260817-001',
    clienteId: 'cliente-1',
    clienteNombre: 'Cliente Prueba',
    clienteRut: '11111111-1',
    sucursalId: 'sucursal-1',
    descripcion: 'Notebook no enciende',
    estado: estado,
    fechaRecepcion: DateTime(2026, 8, 17),
    items: items,
    montoCotizado: montoCotizado,
    montoAprobado: montoAprobado,
    anticipos: anticipos,
    montoAnticipado: montoAnticipado,
    saldoPendiente: saldoPendiente,
    fechaEntrega: null,
    ventaId: ventaId,
  );
}

Future<void> _pumpDetalle(
  WidgetTester tester,
  FakeWorkOrdersRepository fake,
  OrdenTrabajoDetalle orden, {
  FakeSalesRepository? fakeSales,
  List<String> permisos = const ['sales.ordenestrabajo.gestionar'],
}) async {
  fake.detalleARetornar = orden;
  final fakeAuth = FakeAuthRepository()
    ..sesionActiva = true
    ..sesionARetornar = SesionUsuario(
      nombreCompleto: 'Admin Demo',
      email: 'admin@novapos-demo.cl',
      empresaRazonSocial: 'NovaPOS Demo SpA',
      permisos: permisos,
    );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      workOrdersRepositoryProvider.overrideWithValue(fake),
      salesRepositoryProvider.overrideWithValue(fakeSales ?? FakeSalesRepository()),
      authRepositoryProvider.overrideWithValue(fakeAuth),
    ],
    child: const MaterialApp(home: OrdenTrabajoDetalleScreen(ordenTrabajoId: 'ot-1')),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  late FakeWorkOrdersRepository fake;

  setUp(() {
    fake = FakeWorkOrdersRepository();
  });

  testWidgets('Muestra el botón de Imprimir Orden de Trabajo', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemPendiente]));

    expect(find.byKey(const Key('imprimirOrdenTrabajoBoton')), findsOneWidget);
  });

  testWidgets('Un Ítem Pendiente de evaluación muestra el botón Cotizar', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemPendiente]));

    expect(find.byKey(const Key('itemCotizarBoton_item-1')), findsOneWidget);
    expect(find.text('Pendiente de evaluación'), findsOneWidget);
  });

  testWidgets('Un Ítem Cotizado muestra Aprobar y Rechazar, con su monto', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemCotizado], montoCotizado: 80000));

    expect(find.byKey(const Key('itemAprobarBoton_item-2')), findsOneWidget);
    expect(find.byKey(const Key('itemRechazarBoton_item-2')), findsOneWidget);
    expect(find.text(MonedaFormatter.formatear(80000)), findsWidgets);
  });

  testWidgets('Aprobar un Ítem llama al repositorio', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemCotizado]));

    await tester.tap(find.byKey(const Key('itemAprobarBoton_item-2')));
    await tester.pump();
    await tester.pump();

    expect(fake.ultimoItemId, 'item-2');
  });

  testWidgets('Un Ítem Aprobado muestra Iniciar Trabajo', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemAprobado]));

    expect(find.byKey(const Key('itemIniciarTrabajoBoton_item-3')), findsOneWidget);
    expect(find.byKey(const Key('itemAprobarBoton_item-3')), findsNothing);
  });

  testWidgets('Un Ítem EnTrabajo muestra Terminar', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemEnTrabajo]));

    expect(find.byKey(const Key('itemTerminarBoton_item-4')), findsOneWidget);
  });

  testWidgets('Un Ítem Rechazado muestra el motivo y ningún botón de acción', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.lista, items: const [_itemRechazado]));

    expect(find.textContaining('Muy caro'), findsOneWidget);
    expect(find.byKey(const Key('itemAprobarBoton_item-5')), findsNothing);
    expect(find.byKey(const Key('itemRechazarBoton_item-5')), findsNothing);
  });

  testWidgets('Con un Ítem Aprobado ofrece Registrar Anticipo', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemAprobado], montoAprobado: 80000),
    );

    expect(find.byKey(const Key('registrarAnticipoBoton')), findsOneWidget);
  });

  testWidgets('Sin ningún Ítem Aprobado no ofrece Registrar Anticipo', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemCotizado]),
    );

    expect(find.byKey(const Key('registrarAnticipoBoton')), findsNothing);
  });

  testWidgets('Entregada no ofrece Registrar Anticipo aunque tenga montoAprobado', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.entregada, items: const [_itemTerminado], montoAprobado: 80000, ventaId: 'venta-1'),
    );

    expect(find.byKey(const Key('registrarAnticipoBoton')), findsNothing);
  });

  testWidgets('Con Anticipos ya recibidos muestra el listado y el saldo pendiente', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(
        estado: EstadoOrdenTrabajo.enEjecucion,
        items: const [_itemAprobado],
        montoAprobado: 80000,
        montoAnticipado: 30000,
        saldoPendiente: 50000,
        anticipos: [
          AnticipoOrdenTrabajoDetalle(
            id: 'anticipo-1',
            monto: 30000,
            medioPago: MedioPagoAnticipo.efectivo,
            registradoPorNombre: 'Admin Demo',
            fechaRegistro: DateTime.utc(2026, 8, 20, 10),
            estado: EstadoAnticipoOrdenTrabajo.disponible,
          ),
        ],
      ),
    );

    expect(find.textContaining('Efectivo'), findsOneWidget);
    expect(find.textContaining('Admin Demo'), findsOneWidget);
    expect(find.text('Saldo pendiente: ${MonedaFormatter.formatear(50000)}'), findsOneWidget);
  });

  testWidgets('En Lista con montoAprobado muestra el botón Cobrar', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.lista, items: const [_itemTerminado], montoCotizado: 25000, montoAprobado: 25000),
    );

    expect(find.byKey(const Key('cobrarOtBoton')), findsOneWidget);
  });

  testWidgets('En Lista sin montoAprobado (todo rechazado) no ofrece Cobrar', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.lista, items: const [_itemRechazado], montoCotizado: 80000, montoAprobado: null),
    );

    expect(find.byKey(const Key('cobrarOtBoton')), findsNothing);
    expect(find.textContaining('no hay nada que cobrar'), findsOneWidget);
  });

  testWidgets('Entregada con documento emitido muestra el N° de documento, la forma de pago y el botón Imprimir', (tester) async {
    final fakeSales = FakeSalesRepository()
      ..ventaDetalleARetornar = const VentaDetalle(
        id: 'venta-1',
        neto: 21008,
        iva: 3992,
        total: 25000,
        lineas: [],
        pagos: [PagoVentaDetalle(medioPago: MedioPago.efectivo, monto: 25000)],
        dteEmitidoId: 'dte-1',
        tipoDocumentoEmitido: 39,
        folio: 1234,
      );

    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.entregada, items: const [_itemTerminado], ventaId: 'venta-1'),
      fakeSales: fakeSales,
    );

    expect(find.text('Boleta N° 1234'), findsOneWidget);
    expect(find.text('Efectivo \$25.000'), findsOneWidget);
    expect(find.byKey(const Key('imprimirVentaVinculadaBoton')), findsOneWidget);
    expect(find.byKey(const Key('agregarItemBoton')), findsNothing);
  });

  testWidgets('Entregada con pago mixto muestra cada medio de pago con su monto', (tester) async {
    final fakeSales = FakeSalesRepository()
      ..ventaDetalleARetornar = const VentaDetalle(
        id: 'venta-1',
        neto: 21008,
        iva: 3992,
        total: 25000,
        lineas: [],
        pagos: [
          PagoVentaDetalle(medioPago: MedioPago.efectivo, monto: 15000),
          PagoVentaDetalle(medioPago: MedioPago.tarjetaDebito, monto: 10000),
        ],
        dteEmitidoId: 'dte-1',
        tipoDocumentoEmitido: 39,
        folio: 1234,
      );

    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.entregada, items: const [_itemTerminado], ventaId: 'venta-1'),
      fakeSales: fakeSales,
    );

    expect(find.textContaining('Efectivo'), findsOneWidget);
    expect(find.textContaining('Tarjeta Débito'), findsOneWidget);
  });

  testWidgets('Entregada sin documento tributario no ofrece Imprimir', (tester) async {
    await _pumpDetalle(
      tester,
      fake,
      _orden(estado: EstadoOrdenTrabajo.entregada, items: const [_itemTerminado], ventaId: 'venta-1'),
    );

    expect(find.text('Sin documento tributario emitido'), findsOneWidget);
    expect(find.byKey(const Key('imprimirVentaVinculadaBoton')), findsNothing);
  });

  testWidgets('El historial del Ítem se puede expandir y muestra sus eventos', (tester) async {
    await _pumpDetalle(tester, fake, _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: [_itemConHistorial]));

    expect(find.text('Historial (2)'), findsOneWidget);
    expect(find.text('Aprobado — Admin Demo'), findsNothing);

    await tester.tap(find.byKey(Key('itemHistorial_${_itemConHistorial.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Creado — Admin Demo'), findsOneWidget);
    expect(find.text('Aprobado — Admin Demo'), findsOneWidget);
  });

  group('Rol Operador (solo sales.ordenestrabajo.trabajar)', () {
    const permisosOperador = ['sales.ordenestrabajo.trabajar'];

    testWidgets('No ofrece Agregar Ítem ni Registrar Anticipo ni Cobrar', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemAprobado], montoAprobado: 80000),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('agregarItemBoton')), findsNothing);
      expect(find.byKey(const Key('registrarAnticipoBoton')), findsNothing);
    });

    testWidgets('Un Ítem Pendiente de evaluación no muestra el botón Cotizar', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemPendiente]),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('itemCotizarBoton_item-1')), findsNothing);
    });

    testWidgets('Un Ítem Cotizado no muestra Aprobar ni Rechazar', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.enEvaluacion, items: const [_itemCotizado]),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('itemAprobarBoton_item-2')), findsNothing);
      expect(find.byKey(const Key('itemRechazarBoton_item-2')), findsNothing);
    });

    testWidgets('Un Ítem Aprobado sí muestra Iniciar Trabajo', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemAprobado]),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('itemIniciarTrabajoBoton_item-3')), findsOneWidget);
    });

    testWidgets('Un Ítem EnTrabajo sí muestra Terminar', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.enEjecucion, items: const [_itemEnTrabajo]),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('itemTerminarBoton_item-4')), findsOneWidget);
    });

    testWidgets('En Lista con montoAprobado no ofrece Cobrar', (tester) async {
      await _pumpDetalle(
        tester,
        fake,
        _orden(estado: EstadoOrdenTrabajo.lista, items: const [_itemTerminado], montoAprobado: 25000),
        permisos: permisosOperador,
      );

      expect(find.byKey(const Key('cobrarOtBoton')), findsNothing);
    });
  });
}
