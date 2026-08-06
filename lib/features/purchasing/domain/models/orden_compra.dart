import 'purchasing_enums.dart';

/// Espejo de LineaOrdenCompraResumen — NombreProducto/Sku ya resueltos
/// por el backend (mismo criterio que LineaCotizacionDetalle en Sales).
class LineaOrdenCompra {
  const LineaOrdenCompra({
    required this.varianteProductoId,
    required this.nombreProducto,
    required this.sku,
    required this.cantidad,
    required this.costoUnitario,
    required this.cantidadRecibida,
    required this.cantidadPendiente,
  });

  factory LineaOrdenCompra.fromJson(Map<String, dynamic> json) => LineaOrdenCompra(
        varianteProductoId: json['varianteProductoId'] as String,
        nombreProducto: json['nombreProducto'] as String,
        sku: json['sku'] as String,
        cantidad: (json['cantidad'] as num).toDouble(),
        costoUnitario: (json['costoUnitario'] as num).toDouble(),
        cantidadRecibida: (json['cantidadRecibida'] as num).toDouble(),
        cantidadPendiente: (json['cantidadPendiente'] as num).toDouble(),
      );

  final String varianteProductoId;
  final String nombreProducto;
  final String sku;
  final double cantidad;
  final double costoUnitario;
  final double cantidadRecibida;
  final double cantidadPendiente;

  double get subtotal => cantidad * costoUnitario;
}

/// Espejo de OrdenCompraResumen — detalle completo con líneas, para la
/// pantalla de una Orden puntual (ver ObtenerOrdenCompraQuery).
class OrdenCompraDetalle {
  const OrdenCompraDetalle({
    required this.id,
    required this.proveedorId,
    required this.bodegaDestinoId,
    required this.formaPago,
    required this.estado,
    required this.total,
    required this.fechaEnvio,
    required this.fechaRecepcion,
    required this.lineas,
  });

  factory OrdenCompraDetalle.fromJson(Map<String, dynamic> json) => OrdenCompraDetalle(
        id: json['id'] as String,
        proveedorId: json['proveedorId'] as String,
        bodegaDestinoId: json['bodegaDestinoId'] as String,
        formaPago: FormaPago.desdeValor(json['formaPago'] as int),
        estado: EstadoOrdenCompra.desdeValor(json['estado'] as int),
        total: (json['total'] as num).toDouble(),
        fechaEnvio: json['fechaEnvio'] == null ? null : DateTime.parse(json['fechaEnvio'] as String),
        fechaRecepcion: json['fechaRecepcion'] == null ? null : DateTime.parse(json['fechaRecepcion'] as String),
        lineas: (json['lineas'] as List<dynamic>).map((l) => LineaOrdenCompra.fromJson(l as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String proveedorId;
  final String bodegaDestinoId;
  final FormaPago formaPago;
  final EstadoOrdenCompra estado;
  final double total;
  final DateTime? fechaEnvio;
  final DateTime? fechaRecepcion;
  final List<LineaOrdenCompra> lineas;
}

/// Espejo de OrdenCompraResumenListado — fila liviana para el listado,
/// sin líneas, con el nombre del Proveedor ya resuelto.
class OrdenCompraResumenListado {
  const OrdenCompraResumenListado({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.estado,
    required this.total,
    required this.fechaCreacionOrden,
    required this.fechaEnvio,
    required this.fechaRecepcion,
  });

  factory OrdenCompraResumenListado.fromJson(Map<String, dynamic> json) => OrdenCompraResumenListado(
        id: json['id'] as String,
        proveedorId: json['proveedorId'] as String,
        proveedorNombre: json['proveedorNombre'] as String,
        estado: EstadoOrdenCompra.desdeValor(json['estado'] as int),
        total: (json['total'] as num).toDouble(),
        fechaCreacionOrden: DateTime.parse(json['fechaCreacionOrden'] as String),
        fechaEnvio: json['fechaEnvio'] == null ? null : DateTime.parse(json['fechaEnvio'] as String),
        fechaRecepcion: json['fechaRecepcion'] == null ? null : DateTime.parse(json['fechaRecepcion'] as String),
      );

  final String id;
  final String proveedorId;
  final String proveedorNombre;
  final EstadoOrdenCompra estado;
  final double total;
  final DateTime fechaCreacionOrden;
  final DateTime? fechaEnvio;
  final DateTime? fechaRecepcion;
}
