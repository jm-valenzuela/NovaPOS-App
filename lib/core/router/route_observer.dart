import 'package:flutter/material.dart';

/// Observador global de rutas — permite a una pantalla enterarse (vía
/// `RouteAware.didPopNext`) de que volvió a quedar visible porque la ruta
/// empujada encima de ella se cerró, sin depender de que su provider se
/// haya destruido/recreado entretanto (ver ClientesAdminScreen: autorizar
/// un Cupo de Crédito desde SolicitudesCreditoPendientesScreen, alcanzada
/// desde Home y no desde acá, no garantiza que el StateNotifierProvider
/// autoDispose de Clientes se haya reconstruido al volver).
final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();
