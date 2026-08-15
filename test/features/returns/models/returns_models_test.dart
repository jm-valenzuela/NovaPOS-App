import 'package:flutter_test/flutter_test.dart';
import 'package:novapos_app/features/returns/domain/models/nota_credito_cliente_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/venta_confirmada_resumen.dart';
import 'package:novapos_app/features/returns/domain/models/venta_para_devolucion_detalle.dart';

void main() {
  group('VentaConfirmadaResumen', () {
    test('fromJson parsea todos los campos', () {
      final resumen = VentaConfirmadaResumen.fromJson({
        'ventaId': 'venta-1',
        'fechaConfirmacion': '2026-08-13T15:52:19.28Z',
        'clienteId': 'cliente-1',
        'clienteNombre': 'Juan Pérez',
        'clienteRut': '12345678-5',
        'total': 6870.0,
        'cantidadLineas': 1,
      });

      expect(resumen.ventaId, 'venta-1');
      expect(resumen.clienteNombre, 'Juan Pérez');
      expect(resumen.total, 6870.0);
      expect(resumen.cantidadLineas, 1);
    });
  });

  group('LineaVentaParaDevolucion', () {
    test('cantidadDevolvible resta lo ya devuelto de lo comprado', () {
      final linea = LineaVentaParaDevolucion.fromJson({
        'varianteProductoId': 'variante-1',
        'nombreProducto': 'Aguarrás Mineral',
        'sku': 'DEMO-FER-AGUARRAS',
        'cantidad': 3.0,
        'cantidadYaDevuelta': 2.0,
        'precioUnitario': 2290.0,
        'subtotal': 6870.0,
      });

      expect(linea.cantidadDevolvible, 1.0);
    });
  });

  group('VentaParaDevolucionDetalle', () {
    test('fromJson marca clienteEsGenerico y parsea las líneas', () {
      final detalle = VentaParaDevolucionDetalle.fromJson({
        'ventaId': 'venta-1',
        'clienteId': 'cliente-generico',
        'clienteNombre': 'Cliente Genérico',
        'clienteRut': '66666666-6',
        'clienteEsGenerico': true,
        'total': 2290.0,
        'pagadaIntegramenteEnEfectivo': true,
        'lineas': [
          {
            'varianteProductoId': 'variante-1',
            'nombreProducto': 'Aguarrás Mineral',
            'sku': 'DEMO-FER-AGUARRAS',
            'cantidad': 1.0,
            'cantidadYaDevuelta': 0.0,
            'precioUnitario': 2290.0,
            'subtotal': 2290.0,
          },
        ],
      });

      expect(detalle.clienteEsGenerico, isTrue);
      expect(detalle.lineas, hasLength(1));
      expect(detalle.lineas.single.nombreProducto, 'Aguarrás Mineral');
    });
  });

  group('NotaCreditoClienteResumen', () {
    test('fromJson resuelve el Estado desde el valor numérico', () {
      final nota = NotaCreditoClienteResumen.fromJson({
        'id': 'nota-1',
        'folio': 'NC-20260813-001',
        'montoTotal': 4580.0,
        'estado': 2,
        'fechaEmision': '2026-08-13T15:55:02.48Z',
        'motivo': 'Producto defectuoso',
      });

      expect(nota.estado, EstadoNotaCreditoCliente.reembolsada);
      expect(nota.folio, 'NC-20260813-001');
    });

    test('desdeValor por defecto cae en Disponible ante un valor desconocido', () {
      expect(EstadoNotaCreditoCliente.desdeValor(99), EstadoNotaCreditoCliente.disponible);
    });
  });
}
