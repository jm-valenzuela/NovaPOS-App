/// Espejo de FormaPago en NovaPOS.Domain.Purchasing — mismo shape que
/// FormaPago de Sales, pero un tipo Dart aparte (a propósito, ver
/// venta_enums.dart): purchasing no depende de sales ni viceversa.
enum FormaPago {
  contado(0),
  credito(1);

  const FormaPago(this.valorApi);

  final int valorApi;

  static FormaPago desdeValor(int valor) => FormaPago.values.firstWhere((e) => e.valorApi == valor, orElse: () => FormaPago.contado);
}

/// Espejo de EstadoOrdenCompra — ParcialmenteRecibida al final (no
/// reordenado), igual criterio que el backend: el Estado viaja como
/// entero, insertarlo en otro orden desalinearía los valores ya en uso.
enum EstadoOrdenCompra {
  borrador(0),
  enviada(1),
  recibida(2),
  anulada(3),
  parcialmenteRecibida(4);

  const EstadoOrdenCompra(this.valorApi);

  final int valorApi;

  static EstadoOrdenCompra desdeValor(int valor) =>
      EstadoOrdenCompra.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoOrdenCompra.borrador);

  String get etiqueta => switch (this) {
        EstadoOrdenCompra.borrador => 'Borrador',
        EstadoOrdenCompra.enviada => 'Enviada',
        EstadoOrdenCompra.recibida => 'Recibida',
        EstadoOrdenCompra.anulada => 'Anulada',
        EstadoOrdenCompra.parcialmenteRecibida => 'Parcialmente recibida',
      };
}

enum TipoDocumentoRecibido {
  boleta(0),
  factura(1);

  const TipoDocumentoRecibido(this.valorApi);

  final int valorApi;

  static TipoDocumentoRecibido desdeValor(int valor) =>
      TipoDocumentoRecibido.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoDocumentoRecibido.boleta);

  String get etiqueta => this == TipoDocumentoRecibido.boleta ? 'Boleta' : 'Factura';
}

enum EstadoDiscrepancia {
  pendiente(0),
  resuelta(1);

  const EstadoDiscrepancia(this.valorApi);

  final int valorApi;

  static EstadoDiscrepancia desdeValor(int valor) =>
      EstadoDiscrepancia.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoDiscrepancia.pendiente);
}
