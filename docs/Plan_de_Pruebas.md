# PLAN DE PRUEBAS DEL API REST Y ESTRATEGIA DE TESTING MÓVIL — UTRUEQUE

**Asignatura:** Gestión del Proceso de Desarrollo de Software
**Unidad II:** Desarrollo e Integración Continua (Tema I)
**Institución:** Universidad Tecnológica de San Juan del Río (UTSJR)
**Proyecto Integrador:** UTrueque (Marketplace universitario móvil)
**Fecha:** Octubre de 2026
**Versión:** 2.0 (alineada con el código real de la app)

> **Cambios respecto a la versión 1.0:** los casos de prueba estaban escritos en Java/JUnit para un backend que UTrueque no tiene. En esta versión se reescribieron en **Dart**, sobre el código real de la HU-01, y se ejecutan automáticamente en GitHub Actions junto con el Quality Gate.

---

## SECCIÓN 1. PLAN DE PRUEBAS PARA EL API REST

### 1.1 Información general y alcance

UTrueque no tiene un servidor propio. Su **API REST es la que expone Supabase**:

| Servicio de Supabase | Endpoints que usa la app | Para qué |
| --- | --- | --- |
| Auth (GoTrue) | `POST /auth/v1/signup`, `POST /auth/v1/token?grant_type=password`, `POST /auth/v1/logout` | Registro, inicio y cierre de sesión |
| PostgREST | `GET/PATCH /rest/v1/usuarios`, `/rest/v1/divisiones`, `/rest/v1/carreras`, `GET /rest/v1/categorias`, `POST /rest/v1/publicaciones` | Perfil del alumno, catálogos y publicaciones |
| Storage | `POST` y `DELETE /storage/v1/object/...` | Fotos de perfil y de publicaciones |

Por eso, "probar el API REST" significa comprobar que **la app envía las peticiones correctas y reacciona bien a cada respuesta** del servidor (200, 204, 400, 422, sin red).

**Sistema bajo prueba:** App UTrueque v0.1.0 (Flutter) + API REST de Supabase
**Arquitectura de la app:** Clean Architecture (presentación → dominio → datos) con Cubit
**Objetivo de cobertura:** ≥ 80 % en las capas de dominio y datos

**Módulos en alcance:**

| Módulo | Historia | Estado de pruebas |
| --- | --- | --- |
| Autenticación institucional (`@utsjr.edu.mx`) | HU-01 | **Automatizado (7 casos AAA)** |
| Perfil (división y carrera) | HU-02 | Planeado — Sprint 2 |
| Publicaciones y catálogo | HU-03 / HU-04 | HU-03: **Automatizado (10 casos AAA, CP-08 a CP-17)** — Sprint 3; HU-04 planeado |
| Trueques y chat | HU-05+ | Planeado — Sprints 5-7 |

### 1.2 Estrategia: cómo se prueba el API sin depender de internet

Las pruebas usan la **cadena real de la app** y solo cambian la red por un servidor simulado:

```
Caso de uso → AuthRepositoryImpl → AuthRemoteDataSourceImpl → SupabaseClient → [ MockClient HTTP ]
```

El `MockClient` (paquete `http`) responde como lo haría Supabase y guarda cada petición recibida. Así se puede verificar el método, la ruta, los parámetros, el cuerpo y los encabezados (`apikey`, `Authorization: Bearer ...`) de cada llamada. Las pruebas son rápidas, repetibles y no tocan la base de datos real.

### 1.3 Entornos de prueba

| Entorno | Herramientas | Propósito |
| --- | --- | --- |
| Local (cada desarrollador) | VS Code + `flutter test` | Ejecutar las pruebas antes de hacer push (Shift-Left) |
| CI (cada push a `develop` y cada Pull Request) | GitHub Actions (Ubuntu) + SonarQube Cloud | Análisis estático, pruebas, cobertura y Quality Gate |
| Staging (antes de cada release) | Proyecto de Supabase de pruebas + Postman / Newman | Pruebas manuales y de humo contra el API real |

### 1.4 Matriz de tipos de prueba y criterios de éxito

| Tipo de prueba | Herramienta | Alcance | Criterio de aceptación |
| --- | --- | --- | --- |
| Unitarias | `flutter_test` + `mocktail` | Casos de uso y validador de correo | 0 fallos |
| API REST (contrato HTTP) | `flutter_test` + `http/testing` (MockClient) | `/auth/v1/*`, `/rest/v1/usuarios` | Peticiones y respuestas correctas (200, 204, 400, 422) |
| Análisis estático | `flutter analyze` + SonarQube Cloud | Todo `app/lib` | 0 errores del analizador; Quality Gate **PASSED** |
| Cobertura | `flutter test --coverage` | Capas de dominio y datos | ≥ 80 % |
| Humo sobre API real | Postman / Newman | Proyecto Supabase de staging | Flujos de HU-01 sin errores |
| Seguridad (planeado) | Políticas RLS de Supabase + OWASP Mobile Top 10 | Tablas con datos de usuarios | Un usuario no puede leer ni modificar datos de otro |

### 1.5 Criterios de entrada y salida

- **Entrada:** la historia tiene criterios de aceptación definidos y el código compila (`flutter analyze` sin errores).
- **Salida:** todas las pruebas pasan, la cobertura de dominio y datos es ≥ 80 % y el Quality Gate de SonarQube está en **PASSED**. Sin esto, el Pull Request no se puede integrar.

### 1.6 Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Supabase cambia el formato de sus respuestas al actualizar la librería | Las pruebas del API detectan el cambio en CI antes de llegar a `main` |
| Pruebas que dependen de internet o de datos reales | Se usa un servidor HTTP simulado; staging solo para pruebas de humo |
| Baja cobertura en pantallas (UI) | Se cubrirán con pruebas de widgets e integración (Unidad III) |

---

## SECCIÓN 2. CASOS DE PRUEBA DEL API REST (PATRÓN AAA)

Archivo: [`app/test/api/auth_api_rest_test.dart`](../app/test/api/auth_api_rest_test.dart)
Ejecución local: `cd app && flutter test test/api/`

Cada caso sigue el patrón **AAA**:

- **Arrange (Preparar):** se configura qué responderá el API simulado y se crea el caso de uso.
- **Act (Actuar):** se ejecuta una sola acción (registrar, iniciar o cerrar sesión).
- **Assert (Verificar):** se comprueba el resultado y las peticiones HTTP que envió la app.

### Resumen

| ID | Escenario (HU-01) | Endpoint | Respuesta simulada | Resultado esperado |
| --- | --- | --- | --- | --- |
| CP-01 | Inicio de sesión exitoso | `POST /auth/v1/token` + `GET /rest/v1/usuarios` | 200 / 200 | Devuelve el alumno con su división y carrera |
| CP-02 | Registro con correo no institucional | — | (ninguna) | `CorreoNoInstitucionalFailure`, 0 peticiones al API |
| CP-03 | Registro exitoso | `POST /auth/v1/signup` | 200 | Cuenta creada, pendiente de confirmar correo |
| CP-04 | Credenciales incorrectas | `POST /auth/v1/token` | 400 | `CredencialesInvalidasFailure` |
| CP-05 | Sin conexión a internet | — | (ninguna) | `SinConexionFailure`, 0 peticiones al API |
| CP-06 | Correo ya registrado | `POST /auth/v1/signup` | 422 | `ServidorFailure` con el mensaje del servidor |
| CP-07 | Cierre de sesión | `POST /auth/v1/logout` | 204 | La sesión local queda vacía |

### 2.1 CP-01. Inicio de sesión exitoso con correo institucional

- **Arrange:** el API responde 200 con una sesión válida y la tabla `usuarios` devuelve el perfil del alumno. Hay conexión a internet.
- **Act:** se llama a `IniciarSesion` con `ana.lopez@utsjr.edu.mx`.
- **Assert:** el usuario devuelto tiene id, correo confirmado, nombre y carrera; la app hizo exactamente 2 peticiones (login y perfil), la del perfil filtra por `id=eq.<id>` y lleva el token `Bearer` de la sesión.

<details><summary>Ver código</summary>

```dart
test(
    'CP-01: POST /auth/v1/token responde 200 y el inicio de sesión '
    'devuelve el perfil del alumno desde /rest/v1/usuarios', () async {
  // ARRANGE
  api.cuando('POST', '/auth/v1/token', (_) => _respuestaJson(200, _sesionJson()));
  api.cuando(
    'GET',
    '/rest/v1/usuarios',
    (_) => _respuestaJson(200, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _idAlumno,
        'nombre_mostrar': 'Ana López',
        'division': 'Tecnologías de la Información',
        'carrera': 'Ingeniería en Desarrollo y Gestión de Software',
      },
    ]),
  );
  final IniciarSesion iniciarSesion =
      IniciarSesion(repositorio, _RedSimulada(conectado: true));

  // ACT
  final Usuario usuario =
      await iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);

  // ASSERT
  expect(usuario.id, _idAlumno);
  expect(usuario.correo, _correoAlumno);
  expect(usuario.correoConfirmado, isTrue);
  expect(usuario.nombreMostrar, 'Ana López');
  expect(usuario.carrera, 'Ingeniería en Desarrollo y Gestión de Software');

  expect(api.peticiones, hasLength(2));
  final http.Request login = api.peticiones[0];
  expect(login.method, 'POST');
  expect(login.url.path, '/auth/v1/token');
  expect(login.url.queryParameters['grant_type'], 'password');
  expect(login.headers['apikey'], _anonKey);
  expect(jsonDecode(login.body), containsPair('email', _correoAlumno));

  final http.Request perfil = api.peticiones[1];
  expect(perfil.method, 'GET');
  expect(perfil.url.path, '/rest/v1/usuarios');
  expect(perfil.url.queryParameters['id'], 'eq.$_idAlumno');
  expect(perfil.headers['Authorization'], 'Bearer $_tokenAcceso');

  expect(repositorio.usuarioActual?.id, _idAlumno);
});
```
</details>

### 2.2 CP-02. Registro rechazado por correo no institucional

- **Arrange:** se crea `RegistrarUsuario`; el API no tiene ninguna respuesta configurada.
- **Act:** se intenta registrar `ana.lopez@gmail.com`.
- **Assert:** se lanza `CorreoNoInstitucionalFailure` y **no se envió ninguna petición** al API (la validación ocurre antes de usar la red).

<details><summary>Ver código</summary>

```dart
test(
    'CP-02: el registro con un correo no institucional se rechaza '
    'sin enviar ninguna petición al API', () async {
  // ARRANGE
  final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

  // ACT
  final Future<Usuario> intento = registrarUsuario(
    correo: 'ana.lopez@gmail.com',
    contrasena: _contrasena,
    confirmarContrasena: _contrasena,
  );

  // ASSERT
  await expectLater(intento, throwsA(isA<CorreoNoInstitucionalFailure>()));
  expect(api.peticiones, isEmpty);
});
```
</details>

### 2.3 CP-03. Registro exitoso pendiente de confirmación

- **Arrange:** `POST /auth/v1/signup` responde 200 con el usuario creado y sin fecha de confirmación de correo.
- **Act:** se registra el alumno con correo institucional y contraseñas iguales.
- **Assert:** el usuario queda con `correoConfirmado = false`; el cuerpo de la petición lleva el correo y la contraseña; todavía no hay sesión activa.

<details><summary>Ver código</summary>

```dart
test(
    'CP-03: POST /auth/v1/signup responde 200 y la cuenta queda '
    'pendiente de confirmar el correo institucional', () async {
  // ARRANGE
  api.cuando(
    'POST',
    '/auth/v1/signup',
    (_) => _respuestaJson(200, _usuarioAuthJson(correoConfirmado: false)),
  );
  final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

  // ACT
  final Usuario usuario = await registrarUsuario(
    correo: _correoAlumno,
    contrasena: _contrasena,
    confirmarContrasena: _contrasena,
  );

  // ASSERT
  expect(usuario.id, _idAlumno);
  expect(usuario.correo, _correoAlumno);
  expect(usuario.correoConfirmado, isFalse);

  expect(api.peticiones, hasLength(1));
  final http.Request registro = api.peticiones.single;
  expect(registro.method, 'POST');
  expect(registro.url.path, '/auth/v1/signup');
  final Map<String, dynamic> cuerpo =
      jsonDecode(registro.body) as Map<String, dynamic>;
  expect(cuerpo['email'], _correoAlumno);
  expect(cuerpo['password'], _contrasena);

  expect(repositorio.usuarioActual, isNull);
});
```
</details>

### 2.4 CP-04. Credenciales incorrectas (HTTP 400)

- **Arrange:** `POST /auth/v1/token` responde 400 con `invalid_credentials`.
- **Act:** se intenta iniciar sesión con una contraseña incorrecta.
- **Assert:** se lanza `CredencialesInvalidasFailure`, no se consulta el perfil y no queda sesión activa.

<details><summary>Ver código</summary>

```dart
test(
    'CP-04: POST /auth/v1/token responde 400 (credenciales inválidas) '
    'y la app muestra CredencialesInvalidasFailure', () async {
  // ARRANGE
  api.cuando(
    'POST',
    '/auth/v1/token',
    (_) => _respuestaJson(400, <String, dynamic>{
      'code': 'invalid_credentials',
      'error_code': 'invalid_credentials',
      'msg': 'Invalid login credentials',
    }),
  );
  final IniciarSesion iniciarSesion =
      IniciarSesion(repositorio, _RedSimulada(conectado: true));

  // ACT
  final Future<Usuario> intento =
      iniciarSesion(correo: _correoAlumno, contrasena: 'ContrasenaIncorrecta');

  // ASSERT
  await expectLater(intento, throwsA(isA<CredencialesInvalidasFailure>()));
  expect(api.peticiones, hasLength(1));
  expect(api.peticiones.single.url.path, '/auth/v1/token');
  expect(repositorio.usuarioActual, isNull);
});
```
</details>

### 2.5 CP-05. Inicio de sesión sin conexión a internet

- **Arrange:** la conectividad simulada indica que no hay red.
- **Act:** se intenta iniciar sesión.
- **Assert:** se lanza `SinConexionFailure` y no se envió ninguna petición.

<details><summary>Ver código</summary>

```dart
test(
    'CP-05: sin conexión a internet el inicio de sesión falla con '
    'SinConexionFailure y no se llama al API', () async {
  // ARRANGE
  final IniciarSesion iniciarSesion =
      IniciarSesion(repositorio, _RedSimulada(conectado: false));

  // ACT
  final Future<Usuario> intento =
      iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);

  // ASSERT
  await expectLater(intento, throwsA(isA<SinConexionFailure>()));
  expect(api.peticiones, isEmpty);
});
```
</details>

### 2.6 CP-06. Correo ya registrado (HTTP 422)

- **Arrange:** `POST /auth/v1/signup` responde 422 con `user_already_exists`.
- **Act:** se intenta registrar un correo que ya existe.
- **Assert:** se lanza `ServidorFailure` con el mensaje que envió el servidor.

<details><summary>Ver código</summary>

```dart
test(
    'CP-06: POST /auth/v1/signup responde 422 (correo ya registrado) '
    'y el mensaje del servidor llega a la app', () async {
  // ARRANGE
  api.cuando(
    'POST',
    '/auth/v1/signup',
    (_) => _respuestaJson(422, <String, dynamic>{
      'code': 'user_already_exists',
      'error_code': 'user_already_exists',
      'msg': 'User already registered',
    }),
  );
  final RegistrarUsuario registrarUsuario = RegistrarUsuario(repositorio);

  // ACT
  final Future<Usuario> intento = registrarUsuario(
    correo: _correoAlumno,
    contrasena: _contrasena,
    confirmarContrasena: _contrasena,
  );

  // ASSERT
  await expectLater(
    intento,
    throwsA(
      isA<ServidorFailure>()
          .having((ServidorFailure f) => f.mensaje, 'mensaje', 'User already registered'),
    ),
  );
  expect(api.peticiones, hasLength(1));
});
```
</details>

### 2.7 CP-07. Cierre de sesión (HTTP 204)

- **Arrange:** el alumno inicia sesión y `POST /auth/v1/logout` responde 204.
- **Act:** se llama a `cerrarSesion()`.
- **Assert:** ya no hay usuario actual y la petición de logout llevó el token de la sesión.

<details><summary>Ver código</summary>

```dart
test(
    'CP-07: POST /auth/v1/logout responde 204 y la sesión local '
    'queda cerrada', () async {
  // ARRANGE
  api.cuando('POST', '/auth/v1/token', (_) => _respuestaJson(200, _sesionJson()));
  api.cuando(
    'GET',
    '/rest/v1/usuarios',
    (_) => _respuestaJson(200, <Map<String, dynamic>>[]),
  );
  api.cuando('POST', '/auth/v1/logout', (_) => http.Response('', 204));
  await repositorio.iniciarSesion(correo: _correoAlumno, contrasena: _contrasena);
  expect(repositorio.usuarioActual, isNotNull);

  // ACT
  await repositorio.cerrarSesion();

  // ASSERT
  expect(repositorio.usuarioActual, isNull);
  final http.Request logout = api.peticiones.last;
  expect(logout.method, 'POST');
  expect(logout.url.path, '/auth/v1/logout');
  expect(logout.headers['Authorization'], 'Bearer $_tokenAcceso');
});
```
</details>

### 2.8 Pruebas unitarias que ya existían (Sprint 1)

| Archivo | Qué valida |
| --- | --- |
| `test/core/utils/email_validator_test.dart` | Dominio institucional, formato y mensajes de error (7 pruebas) |
| `test/features/auth/domain/registrar_usuario_test.dart` | Reglas del registro: dominio, contraseñas (4 pruebas) |
| `test/features/auth/domain/iniciar_sesion_test.dart` | Escenarios 3, 4 y 5 de HU-01 con `mocktail` (3 pruebas) |

---

## SECCIÓN 3. QUALITY GATE EN SONARQUBE

### 3.1 Dónde se aplica

El Quality Gate se ejecuta en GitHub Actions ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) dentro del check obligatorio `validate`:

1. `flutter analyze`: análisis estático del analizador de Dart.
2. `flutter test --coverage`: pruebas unitarias y del API REST, con reporte `lcov.info`.
3. **Gate de cobertura propio:** [`.github/scripts/quality_gate_cobertura.sh`](../.github/scripts/quality_gate_cobertura.sh) falla si la cobertura de dominio y datos es menor al 80 %.
4. **SonarQube Cloud** (`SonarSource/sonarqube-scan-action@v7`): analiza `app/lib`, importa la cobertura y espera el resultado del Quality Gate (`sonar.qualitygate.wait=true`). Si el resultado es **FAILED**, el pipeline se detiene (Fail-Fast) y el PR no se puede integrar.

El plan **Free** de SonarQube Cloud solo analiza la rama principal del proyecto y los Pull Requests que apuntan a ella. Como el equipo integra todo en `develop`, en SonarQube Cloud la rama principal se llama `develop`. Por eso SonarQube corre en cada **push a `develop`** y en cada **PR hacia `develop`**; en los PR de `develop` hacia `main` (releases) se omite con un aviso, y ahí siguen aplicando los pasos 1 a 3.

La configuración está en [`app/sonar-project.properties`](../app/sonar-project.properties).

### 3.2 Condiciones del Quality Gate

SonarQube Cloud analiza Dart/Flutter de forma nativa (también en el plan Free). En el plan Free no se pueden crear gates personalizados, así que se usa el gate integrado **"Sonar way"**, que evalúa el **código nuevo** (en un PR, las líneas que cambió el PR):

| Condición (código nuevo) | Umbral |
| --- | --- |
| Bugs nuevos | 0 (calificación de confiabilidad A) |
| Vulnerabilidades nuevas | 0 (calificación de seguridad A) |
| Deuda técnica | Calificación de mantenibilidad A |
| Security Hotspots revisados | 100 % |
| Cobertura de pruebas | ≥ 80 % |
| Líneas duplicadas | ≤ 3 % |

Las condiciones de cobertura y duplicación solo se evalúan cuando hay al menos 20 líneas nuevas. Como complemento, el equipo tiene su propio **gate de cobertura en CI** (paso 3), que exige ≥ 80 % sobre todo el código de dominio y datos, no solo sobre el código nuevo.

**Exclusiones de cobertura:** `main.dart`, pantallas (`presentation/pages`), widgets visuales (`presentation/widgets` y `core/widgets`), tema y rutas. Esas partes se validan con pruebas de widgets e integración, no con pruebas unitarias. Los Cubits, casos de uso, repositorios y utilidades sí cuentan.

### 3.3 Activación (una sola vez, la hace el dueño del repo)

1. Entrar a [sonarcloud.io](https://sonarcloud.io) con GitHub, importar la organización `angel050019` (plan **Free**) y analizar el repositorio `UTrueque-DevOps`.
2. En el proyecto: *Administration → Analysis Method* → desactivar **Automatic Analysis** (el análisis lo hace GitHub Actions).
3. En *Administration → Branches and Pull Requests*: renombrar la rama principal (`main`) a **`develop`**.
4. Generar un token en *My Account → Security* y guardarlo en GitHub como secreto `SONAR_TOKEN` (*Settings → Secrets and variables → Actions*).
5. Verificar que `sonar.organization` y `sonar.projectKey` en `app/sonar-project.properties` coincidan con lo que muestra SonarQube Cloud (*Information* del proyecto).

Mientras no exista el secreto, el pipeline corre las pruebas y el gate de cobertura, y muestra un aviso de que se omitió SonarQube.

---

## SECCIÓN 4. PRUEBAS Y HERRAMIENTAS PARA APLICACIONES MÓVILES

La investigación completa está en el documento *Investigación Técnica: Tipos de Pruebas y Herramientas para el Desarrollo Móvil*. Este es el resumen de cómo se aplica a UTrueque:

| Nivel | Qué se prueba en UTrueque | Herramienta | Estado |
| --- | --- | --- | --- |
| Unitarias | Validador de correo, casos de uso de HU-01 | `flutter_test`, `mocktail` | ✅ En CI |
| API REST | Contrato HTTP con Supabase Auth y PostgREST | `flutter_test`, `http/testing` | ✅ En CI |
| Widgets / Golden | Formularios de registro y login, tarjetas de productos | `flutter_test` (`testWidgets`, `matchesGoldenFile`) | Unidad III |
| Integración | Flujo registro → login → feed en emulador | `integration_test`, Patrol | Unidad III |
| E2E en dispositivos reales | Distintas marcas y versiones de Android | Firebase Test Lab | Antes del release |
| Análisis estático | Calidad, bugs, vulnerabilidades, duplicación | `flutter analyze`, SonarQube Cloud | ✅ En CI |
| Rendimiento | FPS (jank), memoria | Flutter DevTools | Por sprint, manual |
| Seguridad | Políticas RLS, almacenamiento seguro de tokens | Supabase RLS, OWASP Mobile Top 10 | Sprint 2 en adelante |

---

## CONCLUSIONES

- **Pruebas sobre el código real:** los casos AAA ya no son ejemplos teóricos; prueban el registro y el inicio de sesión que usa la app y se ejecutan solos en cada Pull Request.
- **El Quality Gate protege `main`:** si una prueba falla, la cobertura baja del 80 % o SonarQube detecta bugs o vulnerabilidades nuevas, el cambio no se integra.
- **Siguiente paso:** al terminar HU-02 (perfil con división y carrera) se agregarán sus casos de API para `PATCH /rest/v1/usuarios` y las pruebas de RLS.
