import '../../../catalog/domain/models/unidad_medida.dart';
import 'venta_enums.dart';

/// Espejo de CotizacionResumen — fila liviana para "rescatar cotización" en el POS.
class CotizacionResumen {
  const CotizacionResumen({
    required this.ventaId,
    this.numeroCotizacion,
    required this.fechaVenta,
    required this.clienteId,
    required this.clienteNombre,
    required this.cantidadLineas,
    required this.total,
  });

  factory CotizacionResumen.fromJson(Map<String, dynamic> json) => CotizacionResumen(
        ventaId: json['ventaId'] as String,
        numeroCotizacion: json['numeroCotizacion'] as String?,
        fechaVenta: DateTime.parse(json['fechaVenta'] as String),
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        cantidadLineas: json['cantidadLineas'] as int,
        total: (json['total'] as num).toDouble(),
      );

  final String ventaId;

  /// Referencia legible ("COT-20260806-001") — null en Cotizaciones guardadas antes de que existiera este campo.
  final String? numeroCotizacion;
  final DateTime fechaVenta;
  final String clienteId;
  final String clienteNombre;
  final int cantidadLineas;
  final double total;
}

/// Espejo de LineaCotizacionDetalle — de solo lectura, con el nombre del
/// Producto ya resuelto (mismo criterio que LineaDescuentoPendienteDetalle).
/// PorcentajeDescuentoAplicado/MontoDescuentoPromocion vienen tal cual de
/// LineaVenta — hechos históricos de qué descuento por línea se aplicó,
/// para que "rescatar" pueda mostrarlo (no solo el Subtotal ya rebajado).
class LineaCotizacionDetalle {
  const LineaCotizacionDetalle({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.porcentajeDescuentoAplicado,
    this.montoDescuentoPromocion,
    this.unidadMedida = UnidadMedida.unidad,
  });

  factory LineaCotizacionDetalle.fromJson(Map<String, dynamic> json) => LineaCotizacionDetalle(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        precioUnitario: (json['precioUnitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        porcentajeDescuentoAplicado: (json['porcentajeDescuentoAplicado'] as num?)?.toDouble(),
        montoDescuentoPromocion: (json['montoDescuentoPromocion'] as num?)?.toDouble(),
        unidadMedida: UnidadMedida.desdeValor(json['unidadMedida'] as int? ?? 0),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final double? porcentajeDescuentoAplicado;
  final double? montoDescuentoPromocion;
  final UnidadMedida unidadMedida;
}

/// Espejo de CotizacionDetalle — detalle completo para rehidratar el
/// carrito del POS al "rescatar" una Cotización guardada.
/// EstadoDescuentoGeneral/DescuentoGeneralPorcentaje/DescuentoGeneralMonto
/// vienen tal cual de Venta — sin esto, rescatar una Cotización con un
/// descuento general ya Autorizado perdía el descuento silenciosamente.
class CotizacionDetalle {
  const CotizacionDetalle({
    required this.ventaId,
    this.numeroCotizacion,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.subtotalLineas,
    required this.total,
    required this.estadoDescuentoGeneral,
    required this.descuentoGeneralPorcentaje,
    required this.descuentoGeneralMonto,
    required this.lineas,
  });

  factory CotizacionDetalle.fromJson(Map<String, dynamic> json) => CotizacionDetalle(
        ventaId: json['ventaId'] as String,
        numeroCotizacion: json['numeroCotizacion'] as String?,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        subtotalLineas: (json['subtotalLineas'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        estadoDescuentoGeneral: EstadoDescuentoGeneral.desdeValor(json['estadoDescuentoGeneral'] as int),
        descuentoGeneralPorcentaje: (json['descuentoGeneralPorcentaje'] as num?)?.toDouble(),
        descuentoGeneralMonto: (json['descuentoGeneralMonto'] as num?)?.toDouble(),
        lineas: (json['lineas'] as List<dynamic>)
            .map((l) => LineaCotizacionDetalle.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  final String ventaId;
  final String? numeroCotizacion;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final double subtotalLineas;
  final double total;
  final EstadoDescuentoGeneral estadoDescuentoGeneral;
  final double? descuentoGeneralPorcentaje;
  final double? descuentoGeneralMonto;
  final List<LineaCotizacionDetalle> lineas;
}
