# NovaPOS — App (Flutter)

Cliente Flutter de NovaPOS — Android, Windows Desktop y Web desde el mismo código. Repo separado del backend (`NovaPOS-Code`) a propósito, para versionar/desplegar cada uno por su cuenta.

## Cómo levantarlo

**1. Backend** (`NovaPOS.Api`) — en `NovaPOS-Code`:

```bash
dotnet run --project src/NovaPOS.Api
```

Si el certificado de desarrollo HTTPS da problemas (`dotnet dev-certs` no confiado), forzar HTTP explícito:

```bash
ASPNETCORE_URLS="http://localhost:6453" ASPNETCORE_ENVIRONMENT="Development" dotnet run --project src/NovaPOS.Api --no-launch-profile
```

Por defecto la app apunta a `http://localhost:6453/api/v1` (o `http://10.0.2.2:6453/api/v1` automáticamente si corre en el emulador de Android, ver `lib/core/config/api_config.dart`). Para apuntar a otro servidor:

```bash
flutter run --dart-define=API_BASE_URL=https://api.novapos.cl/api/v1
```

En Development, `NovaPOS.Api` necesita CORS habilitado para aceptar llamadas desde el origen del servidor Flutter Web (puerto distinto al de la API) — ya viene configurado en el backend (`app.UseCors("DesarrolloFrontend")`, solo en Development).

**2. App Flutter** — en este repo:

```bash
flutter pub get
flutter devices          # lista los destinos disponibles
```

| Destino | Comando |
|---|---|
| Navegador (Chrome) | `flutter run -d chrome` |
| Windows Desktop | `flutter run -d windows` |
| Android (emulador/dispositivo) | `flutter run -d <id-del-emulador>` |

**Si en Chrome las llamadas al backend fallan con "No se pudo conectar con el servidor" pese a que el backend responde bien** (confirmable con `curl`/Swagger): el SDK de Flutter de este proyecto es de 2023 y su compilador de modo debug (DDC) depende de `Intl.v8BreakIterator`, una función que Chrome ya eliminó en versiones recientes. Corre en modo release en su lugar (pierde hot reload, pero evita el problema):

```bash
flutter run -d chrome --release
```

**Cuenta de prueba fija** (para no tener que registrar una Empresa nueva cada vez — ver detalle en el README de `NovaPOS-Code`, no eliminar de la LocalDB). Ya tiene catálogo y Clientes de ejemplo cargados:

| Campo | Valor |
|---|---|
| RUT | `81.814.677-9` |
| Correo | `admin@novapos-demo.cl` |
| Contraseña | `Demo1234!` |

La solución definitiva es actualizar el SDK de Flutter, no hecho todavía en este repo.

Para probar el Punto de Venta hace falta una Empresa ya registrada (pantalla Registro de Empresa) con al menos una Caja cargada (la que UC-01 auto-provisiona alcanza) y un Producto — este último ya se puede crear desde la propia app, en Home → Catálogo.

## Arquitectura

Clean Architecture por feature, mismo espíritu que el backend (`domain` → contratos y modelos sin dependencias externas, `data` → implementación concreta contra la API, `presentation` → widgets + estado):

```
lib/
  core/                    # Compartido entre features
    config/                # ApiConfig — URL base del backend
    network/               # ApiClient (Dio), AuthInterceptor (adjunta/refresca el token)
    storage/               # TokenStorage + SecureStorage (abstracción sobre flutter_secure_storage)
    router/                # GoRouter con redirect automático según sesión
    theme/                 # AppTheme único
    providers/             # Providers de Riverpod compartidos (tokenStorage, apiClient)
  features/
    auth/
      domain/              # AuthRepository (contrato), modelos (AutenticacionResult, etc.)
      data/                # AuthApi (llamadas HTTP crudas), AuthRepositoryImpl
      presentation/
        providers/         # AuthController, RegistroEmpresaController (StateNotifier)
        screens/           # LoginScreen, RegistroEmpresaScreen, SplashScreen
    catalog/
      domain/              # CatalogRepository/CatalogAdminRepository (contratos), ProductoVendible, ProductoAdmin, Departamento/SubDepartamento/Clase/Subclase/Marca
      data/                # CatalogoApi (búsqueda POS), CatalogAdminApi (alta/edición/activar/desactivar)
      presentation/
        providers/         # ProductosAdminController (listado), CatalogFormController (cascada de clasificación + alta)
        screens/           # ProductosAdminScreen (listado), CatalogFormScreen (alta de Producto)
        widgets/           # SelectorConAlta, ClasificacionCascade, EditarProductoDialog, EditarVarianteDialog
    tenancy/
      domain/              # TenancyRepository (contrato), CajaResumen, BodegaVenta
      data/                # TenancyApi, TenancyRepositoryImpl
    inventory/
      domain/              # InventoryRepository (contrato), StockVariante
      data/                # InventarioApi, InventoryRepositoryImpl
    customers/
      domain/              # CustomerRepository (contrato), ClienteResumen
      data/                # CustomerApi, CustomerRepositoryImpl
    sales/
      domain/              # SalesRepository (contrato), LineaCarrito, FormaPago/TipoEntrega
      data/                # VentaApi, SalesRepositoryImpl
      presentation/
        providers/         # BusquedaProductosController (debounce + categoría + stock), BusquedaClientesController, PosCartController (carrito + cobro)
        screens/           # PosScreen — Punto de Venta
        widgets/           # SelectorClienteDialog
    home/
      presentation/screens/  # Menú post-login — punto de entrada a los demás features
```

- **Estado**: Riverpod (`flutter_riverpod`), patrón `StateNotifier` clásico — sin codegen, sin `build_runner`.
- **Navegación**: `go_router`, con `redirect` que observa el estado de sesión (`AuthController`) y manda automáticamente a Login/Home según corresponda.
- **HTTP**: `dio`, un único `ApiClient` compartido por todos los features con `AuthInterceptor` — adjunta el Access Token a cada request y, si el backend responde 401, intenta refrescarlo una vez con el Refresh Token antes de reintentar la request original.
- **Sesión**: `flutter_secure_storage` vía la abstracción `SecureStorage` — permite reemplazarlo por un fake en memoria en los tests (el canal de plataforma real no existe bajo `flutter test`).
- **RUT chileno**: `RutValidator` (`lib/core/utils/rut_validator.dart`) replica el mismo algoritmo de módulo 11 que el backend (`RutChileno.cs`) — nunca se le pide al servidor validar algo que el cliente ya puede rechazar.

## Qué está implementado

- **Login**: RUT + correo + contraseña contra `POST /auth/login`. Si hay una sesión guardada y vigente, la app entra directo a Home sin mostrar Login.
- **Registro de Empresa**: formulario completo (datos de la Empresa + cuenta del Administrador) contra `POST /empresas` — implementa UC-01 del backend. No deja sesión iniciada (mismo criterio que el backend: el JWT se emite recién en Login, no en el registro); al terminar, muestra un diálogo de confirmación y vuelve a Login.
- **Refresh de token automático**: si el backend responde 401 en cualquier llamada, `AuthInterceptor` intenta refrescar una vez con el Refresh Token guardado y reintenta la request original — transparente para el resto de la app.
- **Punto de Venta (POS)**: búsqueda de productos con debounce (`GET /catalogo/productos`), selección de Caja (automática si la Empresa tiene una sola, selector si tiene varias — `GET /cajas`), carrito 100% local (el backend no soporta editar/quitar una línea de Venta ya agregada, así que armar el carrito contra la API línea a línea no es seguro), y al presionar "Cobrar" se ejecuta la secuencia `crearVenta → agregarLinea (por cada línea) → confirmarVenta`. Si la secuencia falla a mitad de camino, el error se muestra y el carrito local NO se vacía (para reintentar sin volver a tipear todo) — la Venta puede quedar en Borrador con líneas parciales en el servidor, limitación conocida y aceptada mientras no exista un endpoint para editar/cancelar una Venta en Borrador.
- **Categorías y stock en el POS**: tabs de filtro por Departamento arriba del buscador (`GET /catalogo/departamentos`, reutilizado del feature de administración de Catálogo) y badge de stock en cada tarjeta de resultado (`POST /inventario/bodegas/{id}/existencias/consultar`, en batch para todos los resultados de una búsqueda a la vez). La Bodega de venta se resuelve una sola vez por sesión de POS a partir de la Sucursal de la Caja seleccionada (`GET /bodegas/venta?sucursalId=`) — mientras no se resuelva, o si la consulta de stock falla, los resultados de búsqueda igual se muestran, solo sin el badge (el stock es puramente informativo, nunca bloquea la venta).
- **Selector de Cliente en el POS**: fila arriba del buscador con el Cliente actual ("Cliente Genérico" por defecto) — tocarla abre `SelectorClienteDialog`, un buscador con debounce (`GET /clientes/buscar?texto=`) igual que el de productos. Elegir un Cliente, tocar "Usar Cliente Genérico" o cerrar el diálogo de cualquier forma deja seleccionado el Cliente Genérico salvo que se haya tocado explícitamente un resultado — simplificación a propósito, no hay un tercer estado "no cambiar nada". El `clienteId` elegido (o `null`) se pasa a `crearVenta`, y se limpia automáticamente después de cada cobro para no arrastrarlo a la siguiente Venta.
- **Desglose Neto/IVA en el POS**: `ResumenVenta` (`neto`/`iva`/`total`) — mientras se arma el carrito se calcula en el cliente con la misma fórmula que el backend (`ResumenVenta.calcular`, 19% con precios IVA incluido); al cobrar, el diálogo de confirmación muestra el desglose real devuelto por `POST /ventas/{id}/confirmar` (`{ neto, iva, total }`), no el estimado local — evita que un redondeo de último momento en el servidor se muestre distinto sin que el Cajero lo note.
- **Escaneo de código de barras en el POS**: botón de cámara (`mobile_scanner`) junto al buscador — abre `EscanearCodigoBarraScreen` en pantalla completa y, al detectar un código, busca ese texto exacto y, si hay una única Variante cuyo `codigoBarras` coincide exactamente, la agrega directo al carrito sin que el Cajero tenga que elegir entre resultados (sin coincidencia exacta, se avisa con un SnackBar en vez de agregar cualquier cosa). La función que abre la cámara real es inyectable en `PosScreen` (mismo criterio que `SecureStorage`/`InMemorySecureStorage`) — los widget tests simulan un escaneo sin tocar la cámara real. **No disponible en Windows desktop** (`mobile_scanner` no tiene implementación ahí): el botón se oculta solo en esa plataforma — un lector físico de código de barras ya funciona como teclado sobre el mismo campo de búsqueda, así que no se pierde la función, solo la variante por cámara. Requirió subir `compileSdkVersion` a 34 y `minSdkVersion` a 21 (Android 5.0+) en `android/app/build.gradle`, y Kotlin de 1.7.10 a 1.9.10 en `android/build.gradle` (evita un choque de clases duplicadas de `kotlin-stdlib` entre la versión que trae `mobile_scanner` y la que traía el proyecto) — verificado con `flutter build apk --debug`, `flutter build web` y `flutter build windows`, los tres compilan limpio.
- **Rediseño visual del POS** (a pedido explícito, con mockup de referencia): marco oscuro (navy) para el header y el panel de carrito, envolviendo un área de trabajo clara con la grilla de productos — mismo patrón visual que una caja registradora física. Grilla de tarjetas de producto (en vez de lista) con badge de stock semáforo (verde/ámbar/rojo), buscador con botón "Escanear" separado, chips de categoría restyleados, y el panel de carrito fijo a la derecha con Cliente, líneas, aviso si alguna línea del carrito no tiene stock (`⚠ ... sin stock — se permitirá la venta`, informativo, nunca bloquea), y desglose Subtotal/IVA/Total. Alcance deliberadamente **solo visual**: los botones "+ Descuento" y "Cotización" del mockup quedan visibles pero deshabilitados (con tooltip "Próximamente"), porque esa lógica no existe en el backend todavía — ver "Qué falta". El botón "Vaciar" sí quedó funcional (`PosCartController.vaciarCarrito()`), al ser una acción puramente local sin dependencia de backend.
- **Venta por peso/volumen (PPUM) en el POS**: para Productos cuya `UnidadMedida` es Kilogramo o Litro, `Producto.PrecioVenta` ya representa directamente el Precio por Unidad de Medida (el concepto de transparencia al consumidor: precio por kilo/litro, sin necesidad de un campo adicional de "contenido neto"), así que solo hizo falta trabajo de UI. Las tarjetas de resultado muestran el precio como "$X/kg" o "$X/L" en vez del precio plano, y tocar una de estas tarjetas (o escanear su código de barras) abre `CantidadPesableDialog` pidiendo el peso o volumen exacto **antes** de agregar al carrito — igual que pesar en una balanza real — en vez de agregar con cantidad 1 y tener que corregir después. La línea del carrito para estos productos reemplaza los botones +/- (que solo tiene sentido para unidades enteras) por un valor tocable ("0.35 kg ✎") que reabre el mismo diálogo, precargado, para corregir el peso. Agregar dos veces el mismo Producto pesable **suma** al peso ya cargado en la línea (permite pesar el mismo artículo suelto en varias tandas), en vez de reemplazarlo. Se introdujo el enum compartido `UnidadMedida` (`lib/features/catalog/domain/models/unidad_medida.dart`) para eliminar la lista `_unidadesMedida` que estaba duplicada en `CatalogFormScreen` y `EditarVarianteDialog`.
- **Catálogo (administración)**: listado de Productos con sus Variantes anidadas (`GET /catalogo/productos/todos`, incluye inactivos), activar/desactivar cada uno con un `Switch` (recarga la lista completa tras cada cambio, sin mutación optimista — catálogo de tamaño de PyME, costo bajo), y alta de Producto + primera Variante (`CatalogFormScreen`) con los 5 combos de clasificación en cascada (Departamento→SubDepartamento→Clase→Subclase, y Marca) — cada combo tiene una opción "+ Nueva..." que crea el nivel al vuelo (`SelectorConAlta`), necesario porque una Empresa recién registrada no tiene ninguna Categoría cargada. Editar un Producto (nombre/descripción/clasificación) o una Variante (precio/unidad/código de barras/color/talla/ubicación) se hace con diálogos chicos desde el listado — el `Sku` nunca es editable, igual que en el backend. **Limitación conocida**: al editar un Producto, la clasificación actual se muestra solo como texto ("Manga Corta · Nike"); si se quiere cambiar, hay que recorrer la cascada completa desde Departamento — el backend no expone un endpoint para resolver la ascendencia completa de una Subclase directamente.
- **Con qué Usuario y Empresa se inició sesión**: el `AppBar` de Home muestra "Nombre completo · Razón social" bajo el título — viene de los 3 campos nuevos que `POST /auth/login` agrega a su respuesta (`nombreCompleto`/`email`/`empresaRazonSocial`, ver README del backend). Se guardan en `TokenStorage` junto a los tokens (el refresh los deja `null` a propósito, así que no se sobrescriben en cada renovación silenciosa) y se leen de ahí al restaurar una sesión guardada al abrir la app — no hace falta volver a llamar a `/auth/login` para saber quién es el Usuario actual. `AuthRepository.login()` pasó de `Future<void>` a `Future<SesionUsuario>`, y se agregó `obtenerSesionActual()` al contrato.
- **Descuento por volumen en el POS y Catálogo** (a pedido explícito, ej. "Desde 15 unidades obtén un 5% de dto." — patrón visto en Sodimac/Easy): `CatalogFormScreen` (alta) y `EditarVarianteDialog` (edición) ganan 2 campos opcionales — cantidad mínima y % de descuento — validados como "ambos o ninguno" del lado del cliente (mismo criterio que `VarianteProducto.ValidarDescuentoVolumen` en el backend). En el POS, `ProductoResultadoTile` muestra un aviso verde ("Desde 15 uds. -5%") en la tarjeta del producto cuando tiene la regla configurada, y `LineaCarrito.subtotal` la aplica **automáticamente** apenas la cantidad de esa línea alcanza el umbral — sin que el Cajero tenga que hacer nada — porque el carrito es 100% local hasta el Cobrar (ver "Punto de Venta (POS)" más abajo), así que el mismo cálculo que hará el backend al agregar la línea real se estima antes, del lado del cliente. `CarritoLineaTile` muestra "X% dto. por volumen aplicado" bajo la cantidad cuando corresponde. Verificado con 2 widget tests nuevos (aviso visible en la tarjeta; el Total del carrito pasa de sin-descuento a con-descuento exactamente al cruzar el umbral, no antes) y `flutter analyze` limpio.
- **Tocar la cantidad de una línea por Unidad para tipear un número grande** (a pedido explícito, ej. "una Empresa que pide 2000 sacos de cemento" — tocar "+" 2000 veces no es razonable): el diálogo que ya existía solo para productos por Kilogramo/Litro (`CantidadPesableDialog`) se generalizó para poder tipear también una cantidad entera exacta en productos por Unidad — se adapta según `producto.unidad.esPesable` (con o sin sufijo de unidad en el label, decimal habilitado o no, exige número entero cuando no es pesable). En `CarritoLineaTile`, el número de la línea (antes texto fijo entre los botones +/-) ahora es tocable (`carritoCantidadUnidad`) y abre el mismo diálogo precargado con la cantidad actual — los botones +/- siguen ahí para ajustes rápidos de a 1. De paso se corrigió un overflow de layout: con una cantidad de varios dígitos, el precio unitario ("x $1.500") ahora se trunca con `TextOverflow.ellipsis` en vez de desbordar la fila. Verificado con 2 widget tests nuevos (tipear 2000 y ver el Total recalculado; rechazar un número no entero) y `flutter analyze` limpio.
- **Promociones por grupo en el POS y Catálogo** (a pedido explícito, "2x1, 6x5 y segundo producto 40% descuento"): mismo mecanismo genérico que el backend — cada N unidades compradas, la última recibe X% de descuento (ver README del backend) — expuesto en la UI con **ambos** niveles a la vez: los 2 campos genéricos crudos y, encima, `PromocionGrupoField` (`lib/features/catalog/presentation/widgets/promocion_grupo_field.dart`), un dropdown con presets amigables (Sin promoción / 2x1 / 3x2 / 6x5 / Segundo producto con % dto. / Personalizada) que resuelve a esos mismos 2 campos — elegir "Personalizada" expone los campos crudos directamente. Se usa en `CatalogFormScreen` (alta) y `EditarVarianteDialog` (edición, con `_inferirTipo` reconstruyendo el preset correcto a partir de los valores guardados). Es **mutuamente excluyente** con el descuento por volumen en la misma Variante (mismo criterio que el backend): configurar ambos a la vez muestra un error y no envía el formulario. `PromocionGrupo.etiqueta()` (`lib/features/catalog/domain/models/promocion_grupo.dart`) centraliza el texto de la etiqueta ("2x1", "2do al 40% dto.", etc.) para no duplicar esa lógica entre la tarjeta de producto y la línea del carrito. En el POS, `ProductoResultadoTile` muestra la etiqueta en la tarjeta cuando corresponde (mutuamente excluyente con el aviso de descuento por volumen, igual que en el dominio) y `LineaCarrito.subtotal` aplica el descuento **automáticamente** apenas se completa un grupo — mismo patrón "estimar localmente antes de Cobrar" que el descuento por volumen — mostrando "2x1 aplicado" (o el preset que corresponda) bajo la cantidad de la línea. Verificado con 2 widget tests nuevos (la etiqueta "2x1" aparece en la tarjeta; el Total no cambia con 1 unidad pero sí al agregar la 2ª, mostrando "aplicado") y `flutter analyze` limpio.
- **Descuento general en el POS con autorización de un Supervisor** (a pedido explícito, "descuento general con autorización de un usuario que tenga el perfil de autorizar descuentos" — "podemos dejar ambos tipos de aprobación, si el supervisor puede estar en piso o desde la oficina"): el botón "+ Descuento" del POS (antes deshabilitado, "Próximamente") ahora abre `SolicitarDescuentoDialog` (% o monto, mutuamente excluyentes). A diferencia de los descuentos por línea, acá el carrito **deja de ser 100% local** en cuanto se pide un descuento: `PosCartController.solicitarDescuento` crea la Venta y agrega las líneas en ese momento (no recién al Cobrar) para tener un `VentaId` real contra el cual pedir la autorización — desde ahí el carrito queda bloqueado para edición (`carritoBloqueado`, deshabilita +/-, quitar y Vaciar en `CarritoLineaTile`/el panel) porque las líneas ya viven en el servidor. Mientras el descuento está Pendiente, un banner en el panel del carrito lo indica y el botón "Cobrar" queda deshabilitado — no se puede cobrar un precio que nadie autorizó. El POS **consulta el estado cada 3 segundos** (`Timer.periodic` en `PosScreen`, `PosCartController.verificarEstadoDescuento`) mientras espera: mismo mecanismo sirve tanto si el Supervisor resuelve al toque parado al lado del Cajero como si tarda porque está en la oficina, no hay dos flujos distintos. Nueva pantalla `DescuentosPendientesScreen` (ruta `/descuentos-pendientes`) para quien autoriza: lista las solicitudes con Autorizar/Rechazar (rechazar pide motivo en `RechazarDescuentoDialog`, obligatorio). **Primera vez que el cliente necesita saber los permisos del Usuario logueado**: no existía ningún mecanismo — se decodifica el claim `permiso` del propio Access Token JWT (`lib/core/auth/jwt_permisos.dart`, sin librería externa, solo para mostrar/ocultar UI — la autorización real la sigue haciendo el backend en cada endpoint) y se guarda en `SesionUsuario.permisos`; el ítem "Descuentos pendientes" en Home solo aparece si `sesion.tienePermiso('sales.descuentos.autorizar')`. Verificado con 13 tests nuevos (`PosCartController`: solicitar crea la Venta y reutiliza el mismo `VentaId` en pedidos siguientes, `cobrar` no hace nada mientras Pendiente, `verificarEstadoDescuento` transiciona el estado; `PosScreen`: el diálogo solicita y bloquea Cobrar; `DescuentosPendientesScreen`: lista, autoriza, rechaza con motivo, estado vacío) y `flutter analyze` limpio.
- **Búsqueda en el listado admin de Catálogo** (a pedido explícito, "en el catálogo de productos no está mostrando todos los productos" — investigado y resuelto como un fix de seguridad en el backend, ver su README: faltaba Row-Level Security en `Productos`/`VariantesProducto` y el catálogo mezclaba Productos de otras Empresas; ya corregido, la Empresa ve exactamente los suyos). Con eso resuelto, un catálogo real de 41 Productos sin buscador seguía siendo difícil de recorrer, así que `ProductosAdminScreen` pasó de `ConsumerWidget` a `ConsumerStatefulWidget` y ganó un `TextField` que **filtra en memoria** (no llama al backend de nuevo) por nombre de Producto, SKU o código de barras de cualquiera de sus Variantes — a diferencia de la búsqueda del POS (que sí pagina contra el servidor, ver `BuscarProductosVendiblesQuery`), acá ya se cargó la lista completa de una sola vez (`ProductosAdminController.cargar()`, sin límite ni paginación, "el catálogo de una PyME es chico"), así que filtrar en memoria es instantáneo y no necesita debounce ni tocar el backend. Botón para limpiar la búsqueda, mensaje "Sin resultados" distinto del de "sin Productos creados todavía". Verificado con 4 widget tests nuevos (filtra por nombre, filtra por SKU, sin resultados muestra el mensaje, limpiar vuelve a mostrar todo — y confirma que no se vuelve a llamar `listarProductos()` al filtrar) y `flutter analyze` limpio.
- **Fix: se podían agregar más Productos a una Venta con un descuento ya solicitado/autorizado** (reportado por el usuario probando la feature de arriba): el bloqueo del carrito (`carritoBloqueado`) se implementó en `CarritoLineaTile` (+/-, quitar, editar cantidad) pero se olvidó el punto de entrada real — tocar una tarjeta nueva en la grilla del POS seguía llamando `PosCartController.agregarProducto` sin ningún chequeo, agregando la línea solo en el estado local sin avisarle al backend: el Total en pantalla subía, pero `Confirmar()` iba a cobrar el subtotal viejo (el que el Supervisor autorizó), ignorando el producto agregado de más. Corregido moviendo el chequeo al controller en vez de a cada botón de la UI por separado — `agregarProducto`, `cambiarCantidad` y `quitarLinea` ahora verifican `carritoBloqueado` ellos mismos (no solo los widgets que los llaman), cerrando esta clase de bug de raíz en vez de parchar el síntoma puntual; `agregarProducto` además dejo un mensaje explicando por qué, en vez de fallar en silencio. De paso, a pedido explícito ("avisar que el descuento será borrado"), el botón "Vaciar" dejó de deshabilitarse cuando hay un descuento en curso — ahora sigue clickeable, pero si `estadoDescuento` no es SinSolicitar pide confirmación primero ("Ya se solicitó un descuento para esta venta... tendrás que pedirlo de nuevo") antes de vaciar. `PosCartController.vaciarCarrito()` pasó de solo limpiar `lineas` a reiniciar todo el estado (`ventaId`, `estadoDescuento`, etc.) — antes dejaba el carrito local vacío pero la Venta ya creada en el servidor seguía "enganchada" (`carritoBloqueado` en true para siempre), lo que habría bloqueado agregar productos nuevos sin ninguna forma de salir de ese estado. Verificado con 4 tests nuevos en `PosCartController` (agregar/cambiar/quitar bloqueados, `vaciarCarrito` reinicia todo) y 3 widget tests nuevos en `PosScreen` (tocar un producto nuevo no lo agrega y muestra el aviso; Vaciar con descuento pide confirmación y respeta Cancelar/Confirmar; Vaciar sin descuento no pide nada) — 86 tests en total, `flutter analyze` limpio.
- **Home**: menú con acceso a Punto de Venta y Catálogo — el resto de las pantallas (Inventario, Compras, etc.) se agregan como nuevos features siguiendo el mismo patrón que `auth/`, `sales/` y `catalog/`.

Verificado con la app real corriendo contra `NovaPOS.Api` real (LocalDB) sirviendo en Web (`flutter run -d web-server`, CORS habilitado): la pantalla de Login renderiza, la navegación a Registro de Empresa funciona, y la escritura en los campos de texto se confirmó real (no simulada) inspeccionando el estado real de los widgets. La interacción de tap final contra el botón de envío no se pudo verificar en vivo en el navegador por una limitación de la herramienta de automatización de esta sesión (el compositing de capturas de pantalla no funcionaba) — el flujo completo (llenar formulario → validar → llamar al repositorio con los datos exactos → mostrar el diálogo de éxito → volver a Login) quedó verificado en cambio con **widget tests reales** (`flutter test`) que ejercitan el árbol de widgets de producción completo (hit-testing real sobre el botón, `Form.validate()` real, `AuthController`/`RegistroEmpresaController` reales), con un `AuthRepository` fake reemplazando solo la capa de red — mismo criterio que los `*RepositorioFalso` del backend.

## Tests

```bash
flutter test
```

Tests unitarios de validación de RUT y del controller de clasificación en cascada de Catálogo (`ProviderContainer`, sin pump de widgets), más widget tests de Login, Registro de Empresa, Punto de Venta y administración de Catálogo que cubren el camino feliz, validación de formulario, manejo de errores del backend, idempotencia de sesión, búsqueda con debounce, filtro por categoría, badge de stock, selector de Cliente, armado del carrito, la secuencia completa de cobro, y listado/activar/desactivar/navegación de Catálogo — todos usando repositorios fake, sin red real ni `flutter_secure_storage` real (el canal de plataforma no existe bajo `flutter test`; ver `SecureStorage`/`InMemorySecureStorage`). **No cubierto por widget tests** (documentado como limitación, no como pendiente silencioso): la interacción real con los `DropdownButtonFormField` de `CatalogFormScreen`/`ClasificacionCascade` ni los diálogos `EditarProductoDialog`/`EditarVarianteDialog` — la lógica que importa (`CatalogFormController`) sí está cubierta directamente.

## Qué falta

- El resto de las pantallas (Inventario, Compras, etc.) — Login, Registro de Empresa, Punto de Venta y Catálogo son la base sobre la que se construye el resto.
- Crear un Cliente nuevo desde el propio selector del POS (el backend ya soporta `POST /clientes`) — hoy solo se puede elegir entre Clientes ya existentes.
- Del diseño objetivo del POS: descuentos por línea y "Cotización" (venta sin confirmar) — ninguno tiene soporte en el backend todavía; los botones ya están en el POS pero deshabilitados ("Próximamente").
- Agregar una Variante adicional a un Producto ya existente desde la app (el backend ya soporta `POST /catalogo/variantes`) — hoy solo se crea la primera Variante junto con el Producto.
- Editar/quitar una línea de una Venta ya agregada en el backend — hoy el carrito del POS es puramente local por esta razón (ver arriba).
- Offline-first real: SQLite local + sincronización contra el Sync Engine del backend (`POST /sync/lotes`, ya construido del lado del servidor) — hoy la app requiere conexión.
- Publicación real en Android (Play Store) y empaquetado del instalable de Windows (MSIX) — por ahora solo se corre en modo desarrollo.
