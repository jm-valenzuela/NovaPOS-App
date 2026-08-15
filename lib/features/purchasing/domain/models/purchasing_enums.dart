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

/// Espejo de CategoriaDocumentoRecibido — clasificación obligatoria de una
/// Factura Interna (DocumentoRecibido sin OrdenCompraId): "estas son las
/// Facturas de proveedor que no constituyen compra de productos o materia
/// prima [...] pueden ser gastos, insumos, servicios, compra de activo
/// fijo, entre otras, que deberán ser clasificadas según su tipo" (pedido
/// explícito del usuario). No aplica cuando el documento sí referencia una
/// Orden de Compra — ver DocumentoRecibido en el backend.
enum CategoriaDocumentoRecibido {
  gasto(0),
  insumo(1),
  servicio(2),
  activoFijo(3),
  otro(4);

  const CategoriaDocumentoRecibido(this.valorApi);

  final int valorApi;

  static CategoriaDocumentoRecibido desdeValor(int valor) =>
      CategoriaDocumentoRecibido.values.firstWhere((e) => e.valorApi == valor, orElse: () => CategoriaDocumentoRecibido.otro);

  String get etiqueta => switch (this) {
        CategoriaDocumentoRecibido.gasto => 'Gasto',
        CategoriaDocumentoRecibido.insumo => 'Insumo',
        CategoriaDocumentoRecibido.servicio => 'Servicio',
        CategoriaDocumentoRecibido.activoFijo => 'Activo Fijo',
        CategoriaDocumentoRecibido.otro => 'Otro',
      };
}

enum EstadoDiscrepancia {
  pendiente(0),
  resuelta(1);

  const EstadoDiscrepancia(this.valorApi);

  final int valorApi;

  static EstadoDiscrepancia desdeValor(int valor) =>
      EstadoDiscrepancia.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoDiscrepancia.pendiente);
}
