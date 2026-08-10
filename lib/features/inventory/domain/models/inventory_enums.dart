/// Espejo de EstadoTomaInventario en NovaPOS.Domain.Inventory.
enum EstadoTomaInventario {
  abierta(0),
  cerrada(1);

  const EstadoTomaInventario(this.valorApi);

  final int valorApi;

  static EstadoTomaInventario desdeValor(int valor) =>
      EstadoTomaInventario.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoTomaInventario.abierta);

  String get etiqueta => this == EstadoTomaInventario.abierta ? 'Abierta' : 'Cerrada';
}

/// Espejo de EstadoTraslado — ParcialmenteRecibido al final (no
/// reordenado), mismo criterio que el backend: el Estado viaja como
/// entero.
enum EstadoTraslado {
  borrador(0),
  enviado(1),
  recibido(2),
  parcialmenteRecibido(3);

  const EstadoTraslado(this.valorApi);

  final int valorApi;

  static EstadoTraslado desdeValor(int valor) =>
      EstadoTraslado.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoTraslado.borrador);

  String get etiqueta => switch (this) {
        EstadoTraslado.borrador => 'Borrador',
        EstadoTraslado.enviado => 'Enviado',
        EstadoTraslado.recibido => 'Recibido',
        EstadoTraslado.parcialmenteRecibido => 'Parcialmente recibido',
      };
}

/// Espejo de TipoMovimientoInventario — usado en la Tarjeta de Existencia (Kardex).
enum TipoMovimientoInventario {
  entrada(0),
  salida(1);

  const TipoMovimientoInventario(this.valorApi);

  final int valorApi;

  static TipoMovimientoInventario desdeValor(int valor) =>
      TipoMovimientoInventario.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoMovimientoInventario.entrada);
}
