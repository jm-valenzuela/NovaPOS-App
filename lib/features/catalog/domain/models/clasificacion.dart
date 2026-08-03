/// Jerarquía de clasificación de Catalog — Departamento → SubDepartamento
/// → Clase → Subclase (ej. "Vestuario" → "Poleras" → "Deportivas" → "Manga
/// Corta"), más Marca (independiente). Espejo de las entidades homónimas
/// en NovaPOS.Domain.Catalog.

class Departamento {
  const Departamento({required this.id, required this.nombre, required this.activo});

  factory Departamento.fromJson(Map<String, dynamic> json) => Departamento(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool,
      );

  final String id;
  final String nombre;
  final bool activo;
}

class SubDepartamento {
  const SubDepartamento({required this.id, required this.departamentoId, required this.nombre, required this.activo});

  factory SubDepartamento.fromJson(Map<String, dynamic> json) => SubDepartamento(
        id: json['id'] as String,
        departamentoId: json['departamentoId'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool,
      );

  final String id;
  final String departamentoId;
  final String nombre;
  final bool activo;
}

class Clase {
  const Clase({required this.id, required this.subDepartamentoId, required this.nombre, required this.activa});

  factory Clase.fromJson(Map<String, dynamic> json) => Clase(
        id: json['id'] as String,
        subDepartamentoId: json['subDepartamentoId'] as String,
        nombre: json['nombre'] as String,
        activa: json['activa'] as bool,
      );

  final String id;
  final String subDepartamentoId;
  final String nombre;
  final bool activa;
}

class Subclase {
  const Subclase({required this.id, required this.claseId, required this.nombre, required this.activa});

  factory Subclase.fromJson(Map<String, dynamic> json) => Subclase(
        id: json['id'] as String,
        claseId: json['claseId'] as String,
        nombre: json['nombre'] as String,
        activa: json['activa'] as bool,
      );

  final String id;
  final String claseId;
  final String nombre;
  final bool activa;
}

class Marca {
  const Marca({required this.id, required this.nombre, required this.activa});

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        activa: json['activa'] as bool,
      );

  final String id;
  final String nombre;
  final bool activa;
}
