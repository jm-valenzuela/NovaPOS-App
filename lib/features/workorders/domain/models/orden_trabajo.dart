/// Espejo de EstadoOrdenTrabajo — resumen computado a partir del Estado
/// de los Ítems de la Orden (ver backend, OrdenTrabajo.RecalcularEstado).
/// Entregada es el único estado propio, puesto explícitamente al cobrar.
enum EstadoOrdenTrabajo {
  recibida(0),
  enEvaluacion(1),
  enEjecucion(2),
  lista(3),
  entregada(4);

  const EstadoOrdenTrabajo(this.valorApi);

  final int valorApi;

  static EstadoOrdenTrabajo desdeValor(int valor) =>
      EstadoOrdenTrabajo.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoOrdenTrabajo.recibida);

  String get etiqueta => switch (this) {
        EstadoOrdenTrabajo.recibida => 'Recibida',
        EstadoOrdenTrabajo.enEvaluacion => 'En Evaluación',
        EstadoOrdenTrabajo.enEjecucion => 'En Ejecución',
        EstadoOrdenTrabajo.lista => 'Lista',
        EstadoOrdenTrabajo.entregada => 'Entregada',
      };
}

/// Espejo de EstadoItemOrdenTrabajo — cada Ítem (un problema/solicitud
/// puntual dentro de la Orden) tiene su propio ciclo de vida, independiente
/// de los demás Ítems de la misma Orden.
enum EstadoItemOrdenTrabajo {
  pendienteEvaluacion(0),
  cotizado(1),
  aprobado(2),
  rechazado(3),
  enTrabajo(4),
  terminado(5);

  const EstadoItemOrdenTrabajo(this.valorApi);

  final int valorApi;

  static EstadoItemOrdenTrabajo desdeValor(int valor) =>
      EstadoItemOrdenTrabajo.values.firstWhere((e) => e.valorApi == valor, orElse: () => EstadoItemOrdenTrabajo.pendienteEvaluacion);

  String get etiqueta => switch (this) {
        EstadoItemOrdenTrabajo.pendienteEvaluacion => 'Pendiente de evaluación',
        EstadoItemOrdenTrabajo.cotizado => 'Cotizado',
        EstadoItemOrdenTrabajo.aprobado => 'Aprobado',
        EstadoItemOrdenTrabajo.rechazado => 'Rechazado',
        EstadoItemOrdenTrabajo.enTrabajo => 'En Trabajo',
        EstadoItemOrdenTrabajo.terminado => 'Terminado',
      };
}

/// Trabajo: mano de obra/servicio, precio a mano. Producto: Variante real
/// del Catálogo, con su precio resuelto por el backend al cotizar.
enum TipoLineaOrdenTrabajo {
  trabajo(0),
  producto(1);

  const TipoLineaOrdenTrabajo(this.valorApi);

  final int valorApi;

  static TipoLineaOrdenTrabajo desdeValor(int valor) =>
      TipoLineaOrdenTrabajo.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoLineaOrdenTrabajo.trabajo);
}

/// Espejo de LineaItemOrdenTrabajoDetalle — descripcion ya viene lista
/// para mostrar (la propia si es Trabajo, o el nombre del Producto ya
/// resuelto desde Catálogo si es Producto). A diferencia del modelo
/// anterior, Monto nunca es null acá — "pendiente" ahora es un estado del
/// Ítem que contiene estas líneas, no de una línea suelta.
class LineaItemOrdenTrabajo {
  const LineaItemOrdenTrabajo({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.varianteProductoId,
    required this.cantidad,
    required this.monto,
  });

  factory LineaItemOrdenTrabajo.fromJson(Map<String, dynamic> json) => LineaItemOrdenTrabajo(
        id: json['id'] as String,
        tipo: TipoLineaOrdenTrabajo.desdeValor(json['tipo'] as int),
        descripcion: json['descripcion'] as String,
        varianteProductoId: json['varianteProductoId'] as String?,
        cantidad: json['cantidad'] == null ? null : (json['cantidad'] as num).toDouble(),
        monto: (json['monto'] as num).toDouble(),
      );

  final String id;
  final TipoLineaOrdenTrabajo tipo;
  final String descripcion;
  final String? varianteProductoId;
  final double? cantidad;
  final double monto;
}

/// Espejo de TipoEventoItemOrdenTrabajo — cada paso de la trazabilidad de un Ítem.
enum TipoEventoItemOrdenTrabajo {
  creado(0),
  cotizado(1),
  aprobado(2),
  rechazado(3),
  trabajoIniciado(4),
  terminado(5),
  observacionEditada(6),
  operadorAsignado(7);

  const TipoEventoItemOrdenTrabajo(this.valorApi);

  final int valorApi;

  static TipoEventoItemOrdenTrabajo desdeValor(int valor) =>
      TipoEventoItemOrdenTrabajo.values.firstWhere((e) => e.valorApi == valor, orElse: () => TipoEventoItemOrdenTrabajo.creado);

  String get etiqueta => switch (this) {
        TipoEventoItemOrdenTrabajo.creado => 'Creado',
        TipoEventoItemOrdenTrabajo.cotizado => 'Cotizado',
        TipoEventoItemOrdenTrabajo.aprobado => 'Aprobado',
        TipoEventoItemOrdenTrabajo.rechazado => 'Rechazado',
        TipoEventoItemOrdenTrabajo.trabajoIniciado => 'Trabajo iniciado',
        TipoEventoItemOrdenTrabajo.terminado => 'Terminado',
        TipoEventoItemOrdenTrabajo.observacionEditada => 'Observación editada',
        TipoEventoItemOrdenTrabajo.operadorAsignado => 'Operador asignado',
      };
}

/// Espejo de EventoHistorialItemDetalle — un paso de la trazabilidad, orden cronológico ascendente.
class EventoHistorialItem {
  const EventoHistorialItem({required this.tipo, required this.fecha, required this.usuarioNombre, required this.detalle});

  factory EventoHistorialItem.fromJson(Map<String, dynamic> json) => EventoHistorialItem(
        tipo: TipoEventoItemOrdenTrabajo.desdeValor(json['tipo'] as int),
        fecha: DateTime.parse(json['fecha'] as String),
        usuarioNombre: json['usuarioNombre'] as String?,
        detalle: json['detalle'] as String?,
      );

  final TipoEventoItemOrdenTrabajo tipo;
  final DateTime fecha;
  final String? usuarioNombre;
  final String? detalle;
}

/// Espejo de ItemOrdenTrabajoDetalle — un problema/solicitud puntual
/// dentro de la Orden, con sus propias líneas (repuestos + mano de obra).
class ItemOrdenTrabajoDetalle {
  const ItemOrdenTrabajoDetalle({
    required this.id,
    required this.descripcion,
    required this.estado,
    required this.observacion,
    required this.asignadoAUsuarioId,
    required this.asignadoANombre,
    required this.motivoRechazo,
    required this.lineas,
    required this.montoTotal,
    this.historial = const [],
  });

  factory ItemOrdenTrabajoDetalle.fromJson(Map<String, dynamic> json) => ItemOrdenTrabajoDetalle(
        id: json['id'] as String,
        descripcion: json['descripcion'] as String,
        estado: EstadoItemOrdenTrabajo.desdeValor(json['estado'] as int),
        observacion: json['observacion'] as String?,
        asignadoAUsuarioId: json['asignadoAUsuarioId'] as String?,
        asignadoANombre: json['asignadoANombre'] as String?,
        motivoRechazo: json['motivoRechazo'] as String?,
        lineas: (json['lineas'] as List<dynamic>).map((l) => LineaItemOrdenTrabajo.fromJson(l as Map<String, dynamic>)).toList(),
        montoTotal: json['montoTotal'] == null ? null : (json['montoTotal'] as num).toDouble(),
        historial: json['historial'] == null
            ? const []
            : (json['historial'] as List<dynamic>).map((e) => EventoHistorialItem.fromJson(e as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String descripcion;
  final EstadoItemOrdenTrabajo estado;
  final String? observacion;
  final String? asignadoAUsuarioId;
  final String? asignadoANombre;
  final String? motivoRechazo;
  final List<LineaItemOrdenTrabajo> lineas;

  /// Null mientras el Ítem sigue Pendiente de evaluación (sin líneas todavía).
  final double? montoTotal;
  final List<EventoHistorialItem> historial;

  bool get pendienteDeEvaluacion => estado == EstadoItemOrdenTrabajo.pendienteEvaluacion;
  bool get cerrado => estado == EstadoItemOrdenTrabajo.rechazado || estado == EstadoItemOrdenTrabajo.terminado;
}

/// Espejo de OrdenTrabajoResumen — fila liviana para el listado.
class OrdenTrabajoResumen {
  const OrdenTrabajoResumen({
    required this.id,
    required this.numero,
    required this.clienteNombre,
    required this.descripcion,
    required this.estado,
    required this.fechaRecepcion,
    required this.montoCotizado,
    required this.montoAprobado,
  });

  factory OrdenTrabajoResumen.fromJson(Map<String, dynamic> json) => OrdenTrabajoResumen(
        id: json['id'] as String,
        numero: json['numero'] as String,
        clienteNombre: json['clienteNombre'] as String,
        descripcion: json['descripcion'] as String,
        estado: EstadoOrdenTrabajo.desdeValor(json['estado'] as int),
        fechaRecepcion: DateTime.parse(json['fechaRecepcion'] as String),
        montoCotizado: json['montoCotizado'] == null ? null : (json['montoCotizado'] as num).toDouble(),
        montoAprobado: json['montoAprobado'] == null ? null : (json['montoAprobado'] as num).toDouble(),
      );

  final String id;
  final String numero;
  final String clienteNombre;
  final String descripcion;
  final EstadoOrdenTrabajo estado;
  final DateTime fechaRecepcion;
  final double? montoCotizado;
  final double? montoAprobado;
}

/// Espejo de OrdenTrabajoDetalle — detalle completo con sus Ítems.
class OrdenTrabajoDetalle {
  const OrdenTrabajoDetalle({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRut,
    required this.sucursalId,
    required this.descripcion,
    required this.estado,
    required this.fechaRecepcion,
    required this.items,
    required this.montoCotizado,
    required this.montoAprobado,
    required this.fechaEntrega,
    required this.ventaId,
  });

  factory OrdenTrabajoDetalle.fromJson(Map<String, dynamic> json) => OrdenTrabajoDetalle(
        id: json['id'] as String,
        numero: json['numero'] as String,
        clienteId: json['clienteId'] as String,
        clienteNombre: json['clienteNombre'] as String,
        clienteRut: json['clienteRut'] as String?,
        sucursalId: json['sucursalId'] as String,
        descripcion: json['descripcion'] as String,
        estado: EstadoOrdenTrabajo.desdeValor(json['estado'] as int),
        fechaRecepcion: DateTime.parse(json['fechaRecepcion'] as String),
        items: (json['items'] as List<dynamic>).map((i) => ItemOrdenTrabajoDetalle.fromJson(i as Map<String, dynamic>)).toList(),
        montoCotizado: json['montoCotizado'] == null ? null : (json['montoCotizado'] as num).toDouble(),
        montoAprobado: json['montoAprobado'] == null ? null : (json['montoAprobado'] as num).toDouble(),
        fechaEntrega: json['fechaEntrega'] == null ? null : DateTime.parse(json['fechaEntrega'] as String),
        ventaId: json['ventaId'] as String?,
      );

  final String id;
  final String numero;
  final String clienteId;
  final String clienteNombre;
  final String? clienteRut;
  final String sucursalId;
  final String descripcion;
  final EstadoOrdenTrabajo estado;
  final DateTime fechaRecepcion;
  final List<ItemOrdenTrabajoDetalle> items;
  final double? montoCotizado;
  final double? montoAprobado;
  final DateTime? fechaEntrega;
  final String? ventaId;
}

/// Espejo de UsuarioResumen — para el selector de "Asignar Operador" (solo
/// id/nombreCompleto importan ahí) y la pantalla de administración de
/// Operarios (que además usa email/rolesNombres/activo).
class UsuarioResumen {
  const UsuarioResumen({
    required this.id,
    required this.nombreCompleto,
    this.email = '',
    this.rolesNombres = const [],
    this.activo = true,
  });

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) => UsuarioResumen(
        id: json['id'] as String,
        nombreCompleto: json['nombreCompleto'] as String,
        email: json['email'] as String? ?? '',
        rolesNombres: json['rolesNombres'] == null ? const [] : List<String>.from(json['rolesNombres'] as List),
        activo: json['activo'] as bool? ?? true,
      );

  final String id;
  final String nombreCompleto;
  final String email;
  final List<String> rolesNombres;
  final bool activo;
}

/// Espejo de RolResumen — para el selector de Rol al crear un Operario.
class RolResumen {
  const RolResumen({required this.id, required this.nombre});

  factory RolResumen.fromJson(Map<String, dynamic> json) => RolResumen(id: json['id'] as String, nombre: json['nombre'] as String);

  final String id;
  final String nombre;
}

/// Espejo de ItemAsignadoResumen — un Ítem abierto asignado a un Operario.
class ItemAsignadoResumen {
  const ItemAsignadoResumen({
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
    required this.itemId,
    required this.descripcion,
    required this.estado,
  });

  factory ItemAsignadoResumen.fromJson(Map<String, dynamic> json) => ItemAsignadoResumen(
        ordenTrabajoId: json['ordenTrabajoId'] as String,
        numeroOrdenTrabajo: json['numeroOrdenTrabajo'] as String,
        itemId: json['itemId'] as String,
        descripcion: json['descripcion'] as String,
        estado: EstadoItemOrdenTrabajo.desdeValor(json['estado'] as int),
      );

  final String ordenTrabajoId;
  final String numeroOrdenTrabajo;
  final String itemId;
  final String descripcion;
  final EstadoItemOrdenTrabajo estado;
}

/// Espejo de OperarioConCarga — "Revisar lo asignado": qué Ítems abiertos tiene cada Operario ahora mismo.
class OperarioConCarga {
  const OperarioConCarga({required this.usuarioId, required this.nombreCompleto, required this.items});

  factory OperarioConCarga.fromJson(Map<String, dynamic> json) => OperarioConCarga(
        usuarioId: json['usuarioId'] as String,
        nombreCompleto: json['nombreCompleto'] as String,
        items: (json['items'] as List<dynamic>).map((i) => ItemAsignadoResumen.fromJson(i as Map<String, dynamic>)).toList(),
      );

  final String usuarioId;
  final String nombreCompleto;
  final List<ItemAsignadoResumen> items;
}

/// Entrada para Agregar/Cotizar un Ítem — espejo de LineaItemOrdenTrabajoInput.
/// En una línea Producto, monto va null (el backend lo resuelve del Catálogo).
class LineaItemOrdenTrabajoInput {
  const LineaItemOrdenTrabajoInput({
    required this.tipo,
    this.descripcion,
    this.varianteProductoId,
    this.cantidad,
    this.monto,
  });

  final TipoLineaOrdenTrabajo tipo;
  final String? descripcion;
  final String? varianteProductoId;
  final double? cantidad;
  final double? monto;

  Map<String, dynamic> toJson() => {
        'tipo': tipo.valorApi,
        'descripcion': descripcion,
        'varianteProductoId': varianteProductoId,
        'cantidad': cantidad,
        'monto': monto,
      };
}
