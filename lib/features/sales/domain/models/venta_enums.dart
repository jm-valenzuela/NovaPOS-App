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
