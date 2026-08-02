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
