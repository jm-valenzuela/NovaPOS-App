/// Espejo de UnidadMedida (enum en el backend, Producto.cs) — el modelo
/// de catálogo lo trae como `int` crudo desde el JSON (ver ProductoVendible/
/// ProductoAdmin), así que este enum solo se usa para interpretarlo donde
/// hace falta un label o una decisión de UI, sin duplicar la lista
/// valor→nombre en cada pantalla que la necesita.
enum UnidadMedida {
  unidad(0, 'Unidad', ''),
  kilogramo(1, 'Kilogramo', 'kg'),
  litro(2, 'Litro', 'L');

  const UnidadMedida(this.valor, this.nombre, this.abreviatura);

  final int valor;
  final String nombre;
  final String abreviatura;

  /// Productos por Kilogramo o Litro se venden por peso/volumen exacto
  /// (ej. 0.350 kg de pan) — a diferencia de Unidad, donde la cantidad
  /// siempre es un conteo entero de piezas (ej. 3 botellas).
  bool get esPesable => this != UnidadMedida.unidad;

  static UnidadMedida desdeValor(int valor) =>
      UnidadMedida.values.firstWhere((u) => u.valor == valor, orElse: () => UnidadMedida.unidad);
}
