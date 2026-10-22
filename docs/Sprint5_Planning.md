# Planeación del Sprint 5 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 5 |
| **Duración** | 1 semana (lunes 19 a viernes 23 de octubre de 2026) |
| **Planeación** | Lunes 19 de octubre de 2026 (acción de mejora del Sprint 4: planear el lunes) |
| **Fecha de cierre (Sprint Review)** | Viernes 23 de octubre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-05-busqueda-filtros` |
| **Issue de GitHub** | #5 (aparece como "HU-03: Búsqueda y Filtrado Académico"; en los documentos y el tablero es **HU-05**) |

## 2. Sprint Goal

Un estudiante con sesión iniciada **encuentra rápido lo que necesita en el Feed**: escribe palabras en el buscador (sin importar mayúsculas ni acentos) y filtra por **categoría, división y carrera**, combinando búsqueda y filtros. Al abrir la app, el Feed muestra primero **lo de su carrera** con un filtro que puede quitar. Si no hay resultados, la app lo dice con claridad y ofrece limpiar los filtros; el scroll infinito, "jalar para actualizar" y los avisos de error y sin conexión siguen funcionando con filtros activos, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-05** (PB-05, issue #5) | Búsqueda y Filtrado Académico | Alta (Must Have) | 8 pts |

> **Como** estudiante que busca insumos académicos, **quiero** filtrar el catálogo por división (en la UTSJR la "facultad" es la división), carrera y palabras clave, **para** encontrar rápidamente los materiales de mis asignaturas.

**Decisiones que deben confirmar los Product Owners (Oziel y Jesus) el lunes:**

1. **Filtros por defecto (regla de negocio del issue #5):** al abrir el Feed se activa un chip **"Mi carrera"** con la carrera del perfil del estudiante. Se ve claramente y se quita con un toque. Así se cumple la regla sin que parezca que "faltan" publicaciones.
2. **"Publicaciones de una división o carrera"** significa: publicadas por un estudiante de esa división o carrera (según su perfil). Las publicaciones no tienen división propia; agregarla sería otra historia.
3. **Chips de categoría:** salen del catálogo de categorías de la base (las 8 actuales), no de una lista fija en la app. El primero es "Todo".

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Ordenar por precio o por cercanía, guardar búsquedas o historial de búsquedas.
- Filtrar por modalidad (Venta, Intercambio, Gratis) o por estado → se puede proponer para un sprint posterior.
- Editar o borrar mis publicaciones → **Sprint 6 (HU-06)**.

**Patrón de diseño:** se sigue usando **State** en las publicaciones. Para los filtros se usa un **objeto de valor** (`FiltrosFeed`): guarda texto, categoría, división y carrera, sabe si hay filtros activos y se "limpia" regresando un objeto nuevo.

Se eligió HU-05 porque el Feed (HU-04) ya muestra todas las publicaciones, pero cuando crezca será difícil encontrar algo sin buscar. Además, el filtrado por división y carrera es el diferenciador del producto frente a Facebook Marketplace.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Confirmar las 3 decisiones de la sección 3 y validar los criterios de aceptación (Gherkin) de HU-05 | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Actualizar el issue #5 con los criterios de la sección 5 y crear el issue "HU-04: Feed de Publicaciones" pendiente | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: configuración de búsqueda sin acentos, función `buscar_publicaciones` (texto + filtros + cursor) e índices | Cadena Vega Jonathan | Develop Team |
| Lógica: `FiltrosFeed`, caso de uso `BuscarPublicaciones` (reemplaza a `ObtenerFeed`), modelo y repositorio contra Supabase | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de casos de uso y modelos, y pruebas del API REST simulado con patrón AAA (CP-28 a CP-35; CP-18 a CP-22 se actualizan a la función nueva) | Cadena Vega Jonathan | Develop Team |
| Estado: `FeedCubit` con filtros (buscar con espera corta al escribir, elegir categoría, división y carrera, limpiar, filtro "Mi carrera" por defecto) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas: buscador funcional, chips de categoría, hoja de filtros División → Carrera, chip "Mi carrera", estado "sin resultados" con ilustración y "Limpiar filtros", con la paleta del logo y Keys (`FeedKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de `FeedCubit` con filtros (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Permiso de galería en iPhone (`ios/Runner/Info.plist`), en cuanto exista la carpeta `ios/` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño del buscador, los filtros y el estado "sin resultados" en Figma **antes** de programar (acción de mejora del Sprint 4) y ajustes visuales en la rama | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 aprobación registrada, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente los escenarios de HU-05 y los casos pendientes de HU-01 a HU-04 contra el build | Torres Valeriano Jesus | Product Owner / Validación |
| Confirmar con Servicios Escolares el acomodo carrera → división (ahora afecta directamente al filtro por división) | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Aplicar en Supabase la migración de HU-05 y confirmar que la de HU-04 ya está aplicada | Orduña Garrido Jose Luis | Scrum Master |
| Aprobar y fusionar el PR #29 `develop` → `main` | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 5, dar seguimiento en las Dailies (martes, miércoles y jueves) y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |
| Actividad individual "Mapa de integración" (Unidad 2): cada integrante sube su versión | Todo el equipo | Todos |

## 5. Criterios de aceptación (Gherkin) - HU-05

```gherkin
Historia: HU-05 Búsqueda y Filtrado Académico (issue #5)
Como estudiante que busca insumos académicos
Quiero filtrar el catálogo por división, carrera y palabras clave
Para encontrar rápidamente los materiales relevantes para mis asignaturas

  Escenario 1: Filtro por defecto con mi carrera
    Dado que el estudiante inició sesión y su perfil es de la carrera "Ingeniería en Desarrollo y Gestión de Software"
    Cuando entra al Feed
    Entonces el chip "Mi carrera" aparece activo
    Y solo se ven publicaciones de estudiantes de su carrera
    Cuando toca el chip "Mi carrera" para quitarlo
    Entonces el Feed muestra las publicaciones de todas las carreras

  Escenario 2: Buscar por palabras
    Dado que el estudiante está en el Feed
    Cuando escribe "calculadora cientifica" en el buscador y deja de escribir
    Entonces el Feed muestra solo las publicaciones cuyo título o descripción contienen todas esas palabras
    Y no importan las mayúsculas, los acentos ni el plural ("Calculadoras Científicas" también aparece)
    Y una palabra a medio escribir también encuentra ("calcu" encuentra "Calculadora")
    Y la app no envía una búsqueda por cada letra, sino una sola al dejar de escribir

  Escenario 3: Filtrar por división y carrera
    Dado que el estudiante abre los filtros del Feed
    Cuando elige la división "Mecatrónica, Desarrollo de Software e Ingeniería Civil" y luego la carrera "Ingeniería en Desarrollo y Gestión de Software"
    Y presiona "Aplicar"
    Entonces el Feed se actualiza mostrando solo publicaciones de estudiantes de esa división y carrera
    Y la lista de carreras solo muestra las de la división elegida

  Escenario 4: Filtrar por categoría
    Dado que el estudiante está en el Feed
    Cuando toca el chip de la categoría "Calculadoras"
    Entonces el Feed muestra solo publicaciones de esa categoría
    Y el chip queda marcado como activo

  Escenario 5: Combinar búsqueda y filtros
    Dado que el estudiante tiene activa la categoría "Libros y apuntes" y la carrera de su perfil
    Cuando busca "calculo"
    Entonces solo aparecen publicaciones que cumplen las tres condiciones
    Y al llegar al final de la lista se cargan las siguientes 20 con los mismos filtros, sin repetir ninguna
    Y al jalar para actualizar se recarga desde el inicio conservando los filtros

  Escenario 6: Búsqueda sin resultados
    Dado que el estudiante busca "Calculadora Científica HP"
    Y no existen publicaciones que coincidan
    Cuando se ejecuta la consulta
    Entonces se muestra una ilustración con el mensaje "No se encontraron artículos que coincidan con tu búsqueda."
    Y aparece el botón "Limpiar filtros"

  Escenario 7: Limpiar filtros
    Dado que el estudiante tiene texto en el buscador y filtros activos
    Cuando presiona "Limpiar filtros"
    Entonces se borran el texto, la categoría, la división y la carrera (incluido "Mi carrera")
    Y el Feed muestra todas las publicaciones Disponibles y Reservadas, como en HU-04

  Escenario 8: Sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando busca, cambia un filtro, carga más o jala para actualizar
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra el mensaje "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y se conservan el texto y los filtros que eligió
    Y al presionar "Reintentar" se repite la búsqueda con esos mismos filtros

  Escenario 9: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante busca o filtra
    Entonces se muestra "No pudimos cargar las publicaciones. Inténtalo de nuevo."
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
    Y aparece el botón "Reintentar", que conserva el texto y los filtros

  Escenario 10: Escribir rápido no mezcla resultados
    Dado que el estudiante escribe "libro" y enseguida lo cambia por "bata"
    Cuando llegan las respuestas del servidor
    Entonces el Feed solo muestra los resultados de "bata"
    Y los resultados de "libro" que lleguen tarde se ignoran
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- La búsqueda revisa **título y descripción**; no busca por nombre del dueño ni por correo.
- Deben aparecer **todas** las palabras escritas, en cualquier orden. Se ignoran palabras vacías ("de", "la", "para") y signos.
- El texto se limita a **100 caracteres** y a **8 palabras** (la app y la base).
- La división y la carrera son las del **perfil del dueño** de la publicación. La carrera solo se puede elegir dentro de la división elegida.
- Con filtros activos se mantienen las reglas del Feed: solo **Disponibles y Reservadas**, de la más nueva a la más vieja, páginas de **20** (máximo 50 por petición).
- Al abrir la app el filtro **"Mi carrera"** está activo; si el estudiante lo quita, se respeta mientras la app siga abierta.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Filtro por defecto | `filtros_feed_test` (de mi perfil → solo carrera), `feed_cubit_test` (iniciar con "Mi carrera"; quitarla recarga sin carrera) |
| 2. Buscar por palabras | `filtros_feed_test` (recorta espacios y 100 caracteres), `buscar_publicaciones_test` (manda el texto), `feed_cubit_test` (espera corta: una sola petición al dejar de escribir), CP-28 (POST `rpc/buscar_publicaciones` con `p_texto` → 200); en la base, pruebas SQL de acentos, plural y prefijo |
| 3. División y carrera | `filtros_feed_test` (cambiar división limpia la carrera), `feed_cubit_test` (aplicar filtros), CP-30 (manda `p_division_id` y `p_carrera_id`) |
| 4. Categoría | `feed_cubit_test` (elegir categoría), CP-31 (solo filtros: no manda `p_texto`) |
| 5. Combinar | `buscar_publicaciones_test` (cursor + filtros), `feed_cubit_test` (cargarMas y actualizar conservan filtros), CP-30 (segunda página con cursor y los mismos filtros) |
| 6. Sin resultados | `feed_cubit_test` (lista vacía con filtros → SinResultados, sin filtros → Vacío), CP-29 (200 con `[]`) |
| 7. Limpiar filtros | `filtros_feed_test` (limpiar → sin filtros), `feed_cubit_test` (limpiar recarga como HU-04) |
| 8. Sin conexión | `buscar_publicaciones_test`, `feed_cubit_test` (conserva texto y filtros; reintentar repite), CP-33 (ninguna petición) |
| 9. Error del servidor | `feed_cubit_test`, CP-32 (500 → mensaje genérico, sin IP ni nombres internos) |
| 10. Escribir rápido | `feed_cubit_test` (ignora la respuesta vieja) |

Otras pruebas del API: CP-34 (sin sesión no se hace ninguna petición) y CP-35 (texto de solo espacios no manda `p_texto`; texto de más de 100 caracteres se recorta).

## 6. Definición de Hecho (Definition of Done) del Sprint 5

- [ ] Las 3 decisiones de la sección 3 confirmadas por los Product Owners y el issue #5 actualizado con estos criterios.
- [ ] Diseño del buscador, los filtros y "sin resultados" en Figma antes de programar las pantallas.
- [ ] Código en `feature/HU-05-busqueda-filtros`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261019120000_hu05_busqueda_filtros.sql` aplicada en Supabase y verificada: busca sin acentos, un visitante sin sesión no puede llamar `buscar_publicaciones` y el Feed de la versión anterior (`feed_publicaciones`) sigue funcionando.
- [ ] Ya no aparece el aviso "La búsqueda y los filtros estarán listos en el Sprint 5".
- [ ] Los 10 escenarios Gherkin de la sección 5 pasan manualmente contra el build (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 a HU-04.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info").
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, **al menos 1 aprobación registrada** y CI en estado PASSED antes del merge (Squash and Merge). El PR menciona el issue #5.
- [ ] Guía de diseño (`docs/Sprint5_Guia_Diseno.md`) entregada a Oziel.
- [ ] PR #29 `develop` → `main` fusionado (versión del Sprint 4).
- [ ] Demo en la Sprint Review del viernes: login → Feed con "Mi carrera" → quitarlo → buscar "calcu" → elegir categoría y carrera → cargar más → buscar algo que no existe → "Limpiar filtros" → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Que el Feed parezca vacío por el filtro por defecto:** si nadie de su carrera ha publicado, el estudiante vería "sin resultados" al abrir la app. Mitigación: el chip "Mi carrera" se ve activo y el mensaje ofrece "Limpiar filtros"; los Product Owners confirman la regla el lunes.
- **Búsqueda que trae cosas de más:** con la raíz de palabras del español, "calculadora" y "cálculo" se volvían iguales y salían libros al buscar calculadoras (se detectó al probar la migración). Mitigación: se busca por inicio de palabra sin acentos y solo se quita la "s" final del plural; probado con 18 casos en Postgres 16.
- **Palabras que se ignoran:** algunas palabras comunes del español ("estado", "para", "de") no cuentan en la búsqueda. Mitigación: si solo se escriben palabras así, el Feed se muestra sin filtro de texto en lugar de quedar vacío; se explica en la guía.
- **Muchas peticiones al escribir y respuestas desordenadas:** Mitigación: la app espera un momento después de la última tecla antes de buscar, y el Cubit ignora las respuestas de búsquedas anteriores (Escenario 10).
- **App vieja instalada:** si se cambiara la función del Feed, los APK de los Sprints 3 y 4 dejarían de cargar. Mitigación: `feed_publicaciones` no se toca; la app nueva usa `buscar_publicaciones`. Se propone quitar la vieja en el Sprint 7.
- **Búsqueda lenta cuando crezca:** Mitigación: índice de texto y de categoría. Con 20 000 publicaciones: búsqueda común ~16 ms, sin resultados ~2 ms, solo filtros ~1 ms.
- **Acomodo carrera → división sin confirmar:** si una carrera está en la división equivocada, el filtro por división mostraría resultados raros. Mitigación: Oziel y Jesus lo confirman con Servicios Escolares; si cambia algo, Jonathan prepara una migración (sin tocar la app).
- **Choque con la rama de diseño del Sprint 4:** Oziel trabaja en `style/ajustes-diseno-sprint4`, que también modifica `feed_page.dart`. Mitigación: se fusiona su rama primero (lunes o martes) y HU-05 sale de ese `develop`; Oziel solo modifica `presentation/pages/`, `presentation/widgets/` y `core/theme/`, y siempre conserva las Keys.
- **Sprint con actividad individual (Mapa de integración):** Mitigación: la base de datos y la lógica se entregan lunes y martes para que pantallas y pruebas avancen en paralelo.

## 8. Seguridad

HU-05 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **Validación de entrada:** el texto se recorta a 100 caracteres y 8 palabras, y se quitan los signos para que nunca se interprete como operadores de búsqueda (probado con `') or 1=1; -- & | !`).
- **Mediación completa:** `buscar_publicaciones` corre con los permisos de quien la llama, así que el RLS se sigue aplicando.
- **Mínimo privilegio:** el rol `anon` (visitante sin cuenta) no puede llamar las funciones nuevas; solo `authenticated`.
- **Minimización:** la búsqueda no revisa ni regresa el correo del dueño.
- **Disponibilidad:** nadie puede pedir más de 50 publicaciones por petición; la app no manda una búsqueda por cada letra.
- **Fallar de forma segura:** los errores llegan como mensajes en español sin detalles internos.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones).

## 9. Pendientes arrastrados del Sprint 4

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | GitHub Issues | Pendiente |
| El issue #1 (Mis publicaciones, HU-06 del tablero) aparece **cerrado** aunque la historia no se ha hecho | Diaz Huerta Diego Oziel | Reabrirlo antes de la planeación del Sprint 6 | Pendiente |
| Aprobar y fusionar el PR #29 `develop` → `main` (el PR #30 se fusionó sin aprobación registrada) | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |
| Diseño del Feed, el Detalle, "Publicar artículo" y la confirmación según Figma | Diaz Huerta Diego Oziel | `style/ajustes-diseno-sprint4` → PR a `develop` | En curso |
| Validación manual: publicación vendida o eliminada mientras se ve el detalle, y casos de error de HU-01, HU-02 y HU-03 | Torres Valeriano Jesus | Checklist de validación con capturas | Pendiente |
| Confirmar con Servicios Escolares el acomodo carrera → división | Oziel y Jesus | Si cambia algo, Jonathan prepara una migración y Jose Luis la aplica | Pendiente |
| Confirmar que la migración de HU-04 está aplicada en Supabase | Orduña Garrido Jose Luis | SQL Editor | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | `chore/plataformas-flutter` (falta la carpeta `ios/`) | Pendiente |

**Orden sugerido de fusión a `develop`:** `style/ajustes-diseno-sprint4` (diseño de Oziel) → `feature/HU-05-busqueda-filtros` (base de datos, lógica, pantallas y pruebas) → ajustes de diseño de HU-05 → `chore/plataformas-flutter` cuando esté lista la carpeta `ios/`. Después de la Review: `develop` → `main`.
