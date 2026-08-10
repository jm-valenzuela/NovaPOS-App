import 'inventory_enums.dart';

/// Espejo de LineaTrasladoResumen — NombreProducto/Sku ya resueltos por el
/// backend (mismo criterio que LineaOrdenCompra en Purchasing).
class LineaTraslado {
  const LineaTraslado({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidadEnviada,
    required this.cantidadRecibida,
    required this.diferencia,
  });

  factory LineaTraslado.fromJson(Map<String, dynamic> json) => LineaTraslado(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidadEnviada: (json['cantidadEnviada'] as num).toDouble(),
        cantidadRecibida: json['cantidadRecibida'] == null ? null : (json['cantidadRecibida'] as num).toDouble(),
        diferencia: json['diferencia'] == null ? null : (json['diferencia'] as num).toDouble(),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidadEnviada;
  final double? cantidadRecibida;
  final double? diferencia;

  /// Lo que aún falta confirmar en destino — null si todavía no se envió.
  double get cantidadPendiente => cantidadRecibida == null ? cantidadEnviada : 0;
}

/// Espejo de TrasladoResumen — detalle completo con líneas.
class TrasladoDetalle {
  const TrasladoDetalle({
    required this.id,
    required this.bodegaOrigenId,
    required this.bodegaDestinoId,
    required this.estado,
    required this.fechaEnvio,
    required this.fechaRecepcion,
    required this.lineas,
  });

  factory TrasladoDetalle.fromJson(Map<String, dynamic> json) => TrasladoDetalle(
        id: json['id'] as String,
        bodegaOrigenId: json['bodegaOrigenId'] as String,
        bodegaDestinoId: json['bodegaDestinoId'] as String,
        estado: EstadoTraslado.desdeValor(json['estado'] as int),
        fechaEnvio: json['fechaEnvio'] == null ? null : DateTime.parse(json['fechaEnvio'] as String),
        fechaRecepcion: json['fechaRecepcion'] == null ? null : DateTime.parse(json['fechaRecepcion'] as String),
        lineas: (json['lineas'] as List<dynamic>).map((l) => LineaTraslado.fromJson(l as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String bodegaOrigenId;
  final String bodegaDestinoId;
  final EstadoTraslado estado;
  final DateTime? fechaEnvio;
  final DateTime? fechaRecepcion;
  final List<LineaTraslado> lineas;
}

/// Espejo de TrasladoListadoResumen — fila liviana para el listado, sin líneas.
class TrasladoListado {
  const TrasladoListado({
    required this.id,
    required this.bodegaOrigenId,
    required this.bodegaDestinoId,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaEnvio,
    required this.fechaRecepcion,
    required this.cantidadLineas,
  });

  factory TrasladoListado.fromJson(Map<String, dynamic> json) => TrasladoListado(
        id: json['id'] as String,
        bodegaOrigenId: json['bodegaOrigenId'] as String,
        bodegaDestinoId: json['bodegaDestinoId'] as String,
        estado: EstadoTraslado.desdeValor(json['estado'] as int),
        fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
        fechaEnvio: json['fechaEnvio'] == null ? null : DateTime.parse(json['fechaEnvio'] as String),
        fechaRecepcion: json['fechaRecepcion'] == null ? null : DateTime.parse(json['fechaRecepcion'] as String),
        cantidadLineas: json['cantidadLineas'] as int,
      );

  final String id;
  final String bodegaOrigenId;
  final String bodegaDestinoId;
  final EstadoTraslado estado;
  final DateTime fechaCreacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaRecepcion;
  final int cantidadLineas;
}
