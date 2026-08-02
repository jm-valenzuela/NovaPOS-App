# NovaPOS — App (Flutter)

Cliente Flutter de NovaPOS — Android, Windows Desktop y Web desde el mismo código. Repo separado del backend (`NovaPOS-Code`) a propósito, para versionar/desplegar cada uno por su cuenta.

## Cómo levantarlo

Requiere el backend `NovaPOS.Api` corriendo (ver el README de `NovaPOS-Code`) — por defecto apunta a `http://localhost:6453/api/v1` (o `http://10.0.2.2:6453/api/v1` automáticamente si corre en el emulador de Android, ver `lib/core/config/api_config.dart`). Para apuntar a otro servidor:

```bash
flutter run --dart-define=API_BASE_URL=https://api.novapos.cl/api/v1
```

```bash
flutter pub get
flutter run -d windows   # o -d chrome, -d <id-del-emulador-android>
```

En Development, `NovaPOS.Api` necesita CORS habilitado para aceptar llamadas desde el origen del servidor Flutter Web (puerto distinto al de la API) — ya viene configurado en el backend (`app.UseCors("DesarrolloFrontend")`, solo en Development).

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
    home/
      presentation/screens/  # Placeholder post-login — próximas features van acá
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
- **Home**: placeholder — el resto de las pantallas (Venta, Inventario, etc.) se agregan como nuevos features siguiendo el mismo patrón que `auth/`.

Verificado con la app real corriendo contra `NovaPOS.Api` real (LocalDB) sirviendo en Web (`flutter run -d web-server`, CORS habilitado): la pantalla de Login renderiza, la navegación a Registro de Empresa funciona, y la escritura en los campos de texto se confirmó real (no simulada) inspeccionando el estado real de los widgets. La interacción de tap final contra el botón de envío no se pudo verificar en vivo en el navegador por una limitación de la herramienta de automatización de esta sesión (el compositing de capturas de pantalla no funcionaba) — el flujo completo (llenar formulario → validar → llamar al repositorio con los datos exactos → mostrar el diálogo de éxito → volver a Login) quedó verificado en cambio con **widget tests reales** (`flutter test`) que ejercitan el árbol de widgets de producción completo (hit-testing real sobre el botón, `Form.validate()` real, `AuthController`/`RegistroEmpresaController` reales), con un `AuthRepository` fake reemplazando solo la capa de red — mismo criterio que los `*RepositorioFalso` del backend.

## Tests

```bash
flutter test
```

21 tests: validación de RUT (unitarios), y widget tests de Login/Registro de Empresa que cubren el camino feliz, validación de formulario, manejo de errores del backend, e idempotencia de sesión — todos usando un `AuthRepository` fake, sin red real.

## Qué falta

- El resto de las pantallas del POS (Venta, Inventario, Catálogo, etc.) — Login y Registro de Empresa son la base sobre la que se construye el resto.
- Offline-first real: SQLite local + sincronización contra el Sync Engine del backend (`POST /sync/lotes`, ya construido del lado del servidor) — hoy la app requiere conexión.
- Publicación real en Android (Play Store) y empaquetado del instalable de Windows (MSIX) — por ahora solo se corre en modo desarrollo.
