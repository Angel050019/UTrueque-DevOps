# Planeación del Sprint 2 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 2 |
| **Duración** | 1 semana |
| **Fecha de inicio** | Lunes 28 de septiembre de 2026 |
| **Fecha de cierre (Sprint Review)** | Viernes 2 de octubre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo (lógica)** | `feature/HU-02-perfil-academico` |
| **Rama de trabajo (diseño)** | `feature/HU-02-perfil-ui` |

## 2. Sprint Goal

Después de iniciar sesión, un estudiante nuevo **completa su perfil académico** (División → Carrera, nombre y foto opcional). Puede **ver y editar** su perfil, los datos quedan **guardados en Supabase y protegidos** para que nadie más pueda cambiarlos, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historias seleccionadas del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-02** (PB-02) | Perfil Académico | Alta | 8 pts |

> **Como** estudiante, **quiero** completar y editar mi perfil académico (nombre, división, carrera y foto) **para que** otros estudiantes sepan quién soy y las publicaciones puedan filtrarse por división y carrera.

Se eligió HU-02 porque es la base de todo lo que sigue: las publicaciones, el filtrado por división/carrera y el chat necesitan saber quién es cada estudiante. Además, HU-01 ya deja al usuario autenticado, así que HU-02 es el siguiente paso natural del flujo.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Corregir el dominio institucional a `@utsjr.edu.mx` (código, pruebas y docs) | Cadena Vega Jonathan | Develop Team |
| Ajustar el pipeline de CI para que corra en los PR hacia `develop` y ejecute las pruebas | Cadena Vega Jonathan | Develop Team |
| Base de datos: catálogo División/Carrera, ajuste de la tabla `usuarios`, reglas de seguridad (RLS) y bucket de fotos `avatars` | Cadena Vega Jonathan | Develop Team |
| Lógica del perfil: entidades, validaciones, casos de uso y repositorio contra Supabase | Cadena Vega Jonathan | Develop Team |
| Estado y navegación: `PerfilCubit`, rutas nuevas y regla "perfil incompleto → Completar perfil" en Splash y Login | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas base funcionales (sin diseño final) y cierre de sesión desde el perfil | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas unitarias de validaciones, casos de uso y Cubit (una por escenario Gherkin como mínimo) | Cadena Vega Jonathan y Gonzalez Casarrubias Luis Angel | Develop Team |
| Subir las carpetas de plataforma de Flutter (`chore/plataformas-flutter`) y abrir el PR del Splash animado | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño visual de las 3 pantallas (Completar perfil, Mi perfil, Editar perfil) en `feature/HU-02-perfil-ui` | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Definir y validar los criterios de aceptación (Gherkin) de HU-02 | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente los escenarios de HU-02 y los pendientes de HU-01 contra el build | Torres Valeriano Jesus | Product Owner / Validación |
| Aplicar la migración en el proyecto de Supabase del equipo | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 2, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 revisor, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |

## 5. Criterios de aceptación (Gherkin) - HU-02

```gherkin
Historia: HU-02 Perfil Académico
Como estudiante de la UTSJR
Quiero completar y editar mi perfil académico (nombre, división, carrera y foto)
Para que otros estudiantes sepan quién soy y las publicaciones puedan filtrarse por división y carrera

  Escenario 1: Completar perfil exitoso
    Dado que el estudiante inició sesión por primera vez y su perfil está incompleto
    Cuando el sistema lo lleva a la pantalla "Completar perfil"
    Y escribe su nombre, elige su división, luego su carrera y opcionalmente una foto JPG o PNG
    Y presiona "Guardar y continuar"
    Entonces el sistema guarda el perfil en Supabase
    Y el estudiante es dirigido al Feed principal
    Y en su próximo inicio de sesión entra directo al Feed

  Escenario 2: Carrera que no pertenece a la división
    Dado que el estudiante está completando o editando su perfil
    Cuando la carrera enviada no pertenece a la división elegida
    Entonces el sistema no guarda el perfil
    Y se muestra el mensaje "La carrera seleccionada no pertenece a la división elegida."

  Escenario 3: Foto mayor a 5 MB
    Dado que el estudiante está completando o editando su perfil
    Cuando elige una foto que pesa más de 5 MB
    Entonces el sistema no sube la foto
    Y se muestra el mensaje "La foto no puede pesar más de 5 MB."
    Y los demás datos del formulario se conservan

  Escenario 4: Editar perfil
    Dado que el estudiante ya tiene su perfil completo
    Cuando entra a "Mi perfil" y presiona "Editar perfil"
    Y cambia su nombre, su carrera o su foto y presiona "Guardar cambios"
    Entonces el sistema guarda los cambios
    Y regresa a "Mi perfil" mostrando los datos actualizados
    Y si no eligió foto nueva, se conserva la foto anterior

  Escenario 5: Sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando intenta cargar o guardar su perfil
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra el mensaje "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y los datos que ya había escrito se conservan
```

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Completar perfil exitoso | `actualizar_perfil_test` (Escenario 1), `perfil_cubit_test` (guardar → Guardado), `resolver_destino_inicial_test` (perfil incompleto → completar, completo → feed) |
| 2. Carrera fuera de la división | `perfil_validator_test`, `actualizar_perfil_test` (Escenario 2), `perfil_cubit_test` (Escenario 2); además la base de datos lo bloquea con una llave foránea |
| 3. Foto mayor a 5 MB | `perfil_validator_test`, `subir_foto_perfil_test`, `actualizar_perfil_test` (Escenario 3), `perfil_cubit_test` (seleccionarFoto); además el bucket rechaza archivos de más de 5 MB |
| 4. Editar perfil | `actualizar_perfil_test` (Escenario 4, conserva la foto), `perfil_cubit_test` (guardar) |
| 5. Sin conexión | `obtener_perfil_test`, `obtener_catalogo_academico_test`, `subir_foto_perfil_test`, `actualizar_perfil_test` (Escenario 5), `perfil_cubit_test` (carga y guardado) |

## 6. Definición de Hecho (Definition of Done) del Sprint 2

- [ ] Código en `feature/HU-02-perfil-academico` (lógica) y `feature/HU-02-perfil-ui` (diseño), con commits siguiendo Conventional Commits.
- [ ] Migración aplicada en Supabase y verificada: un usuario no puede modificar el perfil de otro ni subir fotos fuera de su carpeta.
- [ ] Los 5 escenarios Gherkin de la sección 5 pasan manualmente contra el build (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01.
- [ ] `flutter analyze` sin errores ni advertencias.
- [ ] Pull Request hacia `develop` con la plantilla completa, al menos 1 aprobación y CI en estado PASSED antes del merge (Squash and Merge).
- [ ] Guía de diseño (`docs/Sprint2_Guia_Diseno.md`) entregada a Oziel.
- [ ] Demo en la Sprint Review del viernes: login → completar perfil → Feed → Mi perfil → editar → cerrar sesión.

## 7. Riesgos específicos del sprint

- **Catálogo oficial de Divisiones y Carreras pendiente:** la base de datos trae un catálogo de ejemplo marcado como *PROVISIONAL*. Mitigación: el catálogo vive en tablas, así que cuando tengamos la lista oficial se cambia en Supabase sin tocar la app.
- **Choque entre la rama de lógica y la de diseño:** si Oziel y el equipo de desarrollo editan los mismos archivos, habrá conflictos. Mitigación: Oziel solo modifica `presentation/pages/`, `presentation/widgets/` y `core/theme/`; la lógica vive en el Cubit y los casos de uso.
- **Conflicto con el PR del Splash animado:** ese PR y HU-02 tocan `splash_page.dart` y `pubspec.yaml`. Mitigación: se fusiona primero el Splash y, al resolver el conflicto, se conserva el diseño de Luis Angel y la nueva línea de navegación de HU-02.
- **Migración de la base de datos:** cambia las reglas de seguridad de `usuarios`. Mitigación: la migración se puede correr varias veces sin romper nada y se probó antes contra una copia de la tabla actual.
- **Usuarios de prueba del Sprint 1:** al aplicar la migración, esos usuarios quedan con el perfil incompleto y verán "Completar perfil" en su siguiente inicio de sesión (comportamiento esperado).
- **Foto de perfil en iPhone:** para abrir la galería en iOS hay que agregar un permiso en `ios/Runner/Info.plist`; se hace cuando se suban las carpetas de plataforma.

## 8. Pendientes arrastrados del Sprint 1

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Corregir el dominio institucional de `@alumno.utsjr.edu.mx` a `@utsjr.edu.mx` en código, pruebas y documentación | Cadena Vega Jonathan | `fix/dominio-institucional` → PR a `develop` | Listo para PR |
| Pipeline de CI: no corría en PR hacia `develop` ni ejecutaba `flutter test` | Cadena Vega Jonathan | `fix/dominio-institucional` (commit `ci:`) | Listo para PR |
| Subir las carpetas de plataforma de Flutter (`web/`, `android/`, `ios/`, etc.) y revisar el `.gitignore` | Gonzalez Casarrubias Luis Angel | `chore/plataformas-flutter` → PR a `develop` | `.gitignore` listo; faltan las carpetas |
| Abrir el PR del Splash animado | Gonzalez Casarrubias Luis Angel | `feature/splash-screen-animado` → PR a `develop` | Pendiente |
| Validar manualmente los escenarios de rechazo de HU-01 (correo no institucional, credenciales incorrectas, sin conexión) | Torres Valeriano Jesus | Checklist de validación | Pendiente |

**Orden sugerido de fusión a `develop`:** `fix/dominio-institucional` → `chore/plataformas-flutter` → `feature/splash-screen-animado` → `feature/HU-02-perfil-academico` → `feature/HU-02-perfil-ui`.
