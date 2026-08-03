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
- **Catálogo (administración)**: listado de Productos con sus Variantes anidadas (`GET /catalogo/productos/todos`, incluye inactivos), activar/desactivar cada uno con un `Switch` (recarga la lista completa tras cada cambio, sin mutación optimista — catálogo de tamaño de PyME, costo bajo), y alta de Producto + primera Variante (`CatalogFormScreen`) con los 5 combos de clasificación en cascada (Departamento→SubDepartamento→Clase→Subclase, y Marca) — cada combo tiene una opción "+ Nueva..." que crea el nivel al vuelo (`SelectorConAlta`), necesario porque una Empresa recién registrada no tiene ninguna Categoría cargada. Editar un Producto (nombre/descripción/clasificación) o una Variante (precio/unidad/código de barras/color/talla/ubicación) se hace con diálogos chicos desde el listado — el `Sku` nunca es editable, igual que en el backend. **Limitación conocida**: al editar un Producto, la clasificación actual se muestra solo como texto ("Manga Corta · Nike"); si se quiere cambiar, hay que recorrer la cascada completa desde Departamento — el backend no expone un endpoint para resolver la ascendencia completa de una Subclase directamente.
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
- Del diseño objetivo del POS: descuentos por línea, desglose Subtotal/IVA/Total, "Cotización" (venta sin confirmar) y escaneo de código de barras por cámara — ninguno tiene soporte en el backend todavía.
- Agregar una Variante adicional a un Producto ya existente desde la app (el backend ya soporta `POST /catalogo/variantes`) — hoy solo se crea la primera Variante junto con el Producto.
- Editar/quitar una línea de una Venta ya agregada en el backend — hoy el carrito del POS es puramente local por esta razón (ver arriba).
- Offline-first real: SQLite local + sincronización contra el Sync Engine del backend (`POST /sync/lotes`, ya construido del lado del servidor) — hoy la app requiere conexión.
- Publicación real en Android (Play Store) y empaquetado del instalable de Windows (MSIX) — por ahora solo se corre en modo desarrollo.
