/// Espejo de FormaPago en NovaPOS.Domain.Sales — la Api no serializa
/// enums como string (sin JsonStringEnumConverter configurado), viajan
/// como el valor numérico tal cual.
enum FormaPago {
  contado(0),
  credito(1);

  const FormaPago(this.valorApi);

  final int valorApi;
}

/// Espejo de TipoEntrega — Inmediata es el único camino que usa el POS
/// por ahora (Diferida involucra agendar despacho, fuera de alcance de
/// esta primera versión de Venta).
enum TipoEntrega {
  inmediata(0),
  diferida(1);

  const TipoEntrega(this.valorApi);

  final int valorApi;
}

/// Espejo de EstadoDescuentoGeneral en NovaPOS.Domain.Sales.Venta —
/// SinSolicitar es el estado por defecto (nunca se pidió un descuento).
enum EstadoDescuentoGeneral {
  sinSolicitar(0),
  pendiente(1),
  autorizado(2),
  rechazado(3);

  const EstadoDescuentoGeneral(this.valorApi);

  final int valorApi;

  static EstadoDescuentoGeneral desdeValor(int valor) =>
      EstadoDescuentoGeneral.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoDescuentoGeneral.sinSolicitar);
}

/// Espejo de TipoDteExterno en NovaPOS.Domain.Sales — el Cajero elige uno de
/// estos dos al confirmar (ya no se infiere automático según el RUT del
/// Cliente). Los valores son los códigos reales del SII (33/39), igual
/// criterio que el backend.
enum TipoDocumento {
  boleta(39),
  factura(33);

  const TipoDocumento(this.valorApi);

  final int valorApi;

  String get etiqueta => switch (this) {
        TipoDocumento.boleta => 'Boleta',
        TipoDocumento.factura => 'Factura',
      };
}

/// Espejo de MedioPago en NovaPOS.Domain.Sales / NovaPOS.Domain.Receivables
/// — un solo enum Dart compartido entre Sales y Receivables (a diferencia
/// del backend, acá no hay restricción de ADR-007 sobre duplicar tipos).
enum MedioPago {
  efectivo(0),
  tarjetaDebito(1),
  tarjetaCredito(2);

  const MedioPago(this.valorApi);

  final int valorApi;

  String get etiqueta => switch (this) {
        MedioPago.efectivo => 'Efectivo',
        MedioPago.tarjetaDebito => 'Tarjeta Débito',
        MedioPago.tarjetaCredito => 'Tarjeta Crédito',
      };
}
