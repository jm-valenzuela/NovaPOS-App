import 'inventory_enums.dart';

/// Espejo de LineaTomaInventarioResumen — NombreProducto/Sku ya resueltos
/// por el backend (mismo criterio que LineaOrdenCompra en Purchasing).
class LineaTomaInventario {
  const LineaTomaInventario({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidadSistema,
    required this.cantidadContada,
    required this.diferencia,
  });

  factory LineaTomaInventario.fromJson(Map<String, dynamic> json) => LineaTomaInventario(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidadSistema: (json['cantidadSistema'] as num).toDouble(),
        cantidadContada: (json['cantidadContada'] as num).toDouble(),
        diferencia: (json['diferencia'] as num).toDouble(),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidadSistema;
  final double cantidadContada;
  final double diferencia;
}

/// Espejo de TomaInventarioResumen — detalle completo con líneas.
class TomaInventarioDetalle {
  const TomaInventarioDetalle({
    required this.id,
    required this.bodegaId,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.lineas,
  });

  factory TomaInventarioDetalle.fromJson(Map<String, dynamic> json) => TomaInventarioDetalle(
        id: json['id'] as String,
        bodegaId: json['bodegaId'] as String,
        estado: EstadoTomaInventario.desdeValor(json['estado'] as int),
        fechaApertura: DateTime.parse(json['fechaApertura'] as String),
        fechaCierre: json['fechaCierre'] == null ? null : DateTime.parse(json['fechaCierre'] as String),
        lineas: (json['lineas'] as List<dynamic>).map((l) => LineaTomaInventario.fromJson(l as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String bodegaId;
  final EstadoTomaInventario estado;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final List<LineaTomaInventario> lineas;
}

/// Espejo de TomaInventarioListadoResumen — fila liviana para el listado, sin líneas.
class TomaInventarioListado {
  const TomaInventarioListado({
    required this.id,
    required this.bodegaId,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.cantidadLineas,
  });

  factory TomaInventarioListado.fromJson(Map<String, dynamic> json) => TomaInventarioListado(
        id: json['id'] as String,
        bodegaId: json['bodegaId'] as String,
        estado: EstadoTomaInventario.desdeValor(json['estado'] as int),
        fechaApertura: DateTime.parse(json['fechaApertura'] as String),
        fechaCierre: json['fechaCierre'] == null ? null : DateTime.parse(json['fechaCierre'] as String),
        cantidadLineas: json['cantidadLineas'] as int,
      );

  final String id;
  final String bodegaId;
  final EstadoTomaInventario estado;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final int cantidadLineas;
}
