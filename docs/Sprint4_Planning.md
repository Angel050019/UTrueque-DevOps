# Planeación del Sprint 4 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 4 |
| **Duración** | 1 semana (lunes 12 a viernes 16 de octubre de 2026) |
| **Inicio real del trabajo** | Martes 13 de octubre de 2026 (planeación y migración) |
| **Fecha de cierre (Sprint Review)** | Viernes 16 de octubre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-04-feed-publicaciones` |
| **Issue de GitHub** | **Por crear:** "HU-04: Feed de Publicaciones". Hoy no existe un issue para el Feed (el issue #1 se llama "HU-04" pero es *Gestión de Mis Publicaciones*, que en el tablero es HU-06). |

## 2. Sprint Goal

Un estudiante con sesión iniciada **ve en el Feed las publicaciones de sus compañeros** (las más nuevas primero), las va **cargando por páginas** al hacer scroll, puede **jalar para actualizar** y, al tocar una, **ve su detalle completo**: todas las fotos, la descripción, el precio o la modalidad, el estado y quién la publicó con su división y carrera. La app avisa con claridad cuando no hay publicaciones, no hay internet, el servidor falla o la publicación se vendió o se borró, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-04** (PB-04, issue por crear) | Feed de Publicaciones | Alta | 8 pts |

> **Como** estudiante de la UTSJR con sesión iniciada, **quiero** ver las publicaciones de mis compañeros en un Feed y abrir el detalle de cada una, **para** encontrar artículos académicos que me sirvan y saber quién los ofrece.

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Búsqueda y filtros por categoría, división y carrera → **Sprint 5 (HU-05, issue #5)**. El buscador y los filtros del Feed siguen visibles pero sin funcionar.
- Editar, borrar o cambiar el estado de mis publicaciones → **Sprint 6 (HU-06, issue #1)**.
- Contactar al dueño → **Sprint 7 (HU-07, chat)**. El botón existe pero abre "En desarrollo".

**Patrón de diseño:** se sigue usando **State** (de HU-03): el estado de la publicación decide qué muestra el detalle (Disponible → se puede contactar; Reservado → aviso y sin contactar; Vendido → aviso "Ya fue vendido").

Se eligió HU-04 porque ya hay publicaciones guardadas (HU-03) pero hoy el Feed solo muestra una lista sencilla de 20 y al tocarlas sale "En desarrollo". Sin Feed y detalle no tiene sentido la búsqueda (HU-05) ni el chat (HU-07).

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Crear el issue "HU-04: Feed de Publicaciones" en GitHub con los criterios de la sección 5 | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: vista `publicaciones_detalle` (publicación + categoría + perfil público del dueño), función `feed_publicaciones` (Feed por páginas) e índice para el Feed | Cadena Vega Jonathan | Develop Team |
| Lógica: `PaginaFeed`, `DetallePublicacion`, casos de uso `ObtenerFeed` y `ObtenerDetallePublicacion`, fallo "publicación no encontrada", modelo y repositorio contra Supabase | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de casos de uso y modelos, y pruebas del API REST simulado con patrón AAA (CP-20 a CP-27) | Cadena Vega Jonathan | Develop Team |
| Estado y navegación: `FeedCubit` (primera página, siguiente página, actualizar), `DetallePublicacionCubit`, ruta `/publicacion` y quitar "En desarrollo" de la tarjeta del Feed y de "Ver publicación" | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas Feed (scroll infinito, jalar para actualizar, estados vacío/error/sin conexión) y Detalle (carrusel de fotos, datos, dueño, avisos por estado) con la paleta del logo y Keys (`FeedKeys`, `DetalleKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de `FeedCubit` y `DetallePublicacionCubit` (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Permiso de galería en iPhone (`ios/Runner/Info.plist`), en cuanto exista la carpeta `ios/` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Definir y validar los criterios de aceptación (Gherkin) de HU-04 | Diaz Huerta Diego Oziel | Product Owner |
| Diseño del Feed y del Detalle en Figma y ajustes visuales en la rama (incluye los pendientes de "Publicar artículo" y la confirmación) | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 revisor, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente los escenarios de HU-04 y los casos de error pendientes de HU-01, HU-02 y HU-03 contra el build | Torres Valeriano Jesus | Product Owner / Validación |
| Entregar las actividades de seguridad de la Unidad 2, Tema 1 (jueves 15 de octubre) | Torres Valeriano Jesus | Product Owner / Validación |
| Confirmar con Servicios Escolares el acomodo carrera → división | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Aplicar en Supabase la migración de HU-04 y correr las pruebas de la sección 4.2 de la guía de seguridad | Orduña Garrido Jose Luis | Scrum Master |
| Pasar `develop` → `main` como versión del Sprint 3 (PR con aprobación) | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 4, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-04

```gherkin
Historia: HU-04 Feed de Publicaciones
Como estudiante de la UTSJR con sesión iniciada
Quiero ver las publicaciones de mis compañeros en un Feed y abrir el detalle de cada una
Para encontrar artículos académicos que me sirvan y saber quién los ofrece

  Escenario 1: Ver el Feed
    Dado que el estudiante inició sesión y su perfil está completo
    Cuando entra al Feed
    Entonces ve las 20 publicaciones más recientes en estado "Disponible" o "Reservado"
    Y cada tarjeta muestra la portada, el título, la categoría, el nombre del dueño,
      el precio (en Venta) o la modalidad (Intercambio o Gratis) y el estado
    Y las publicaciones "Vendidas" no aparecen

  Escenario 2: Cargar más al hacer scroll
    Dado que el estudiante está viendo el Feed y hay más de 20 publicaciones
    Cuando llega al final de la lista
    Entonces se cargan las siguientes 20 sin repetir ninguna
    Y cuando ya no hay más se muestra "Ya viste todas las publicaciones."

  Escenario 3: Jalar para actualizar
    Dado que el estudiante está viendo el Feed
    Y un compañero acaba de publicar un artículo
    Cuando jala la lista hacia abajo
    Entonces el Feed se vuelve a cargar desde el inicio
    Y la publicación nueva aparece hasta arriba

  Escenario 4: Feed vacío
    Dado que no hay publicaciones Disponibles ni Reservadas
    Cuando el estudiante entra al Feed
    Entonces se muestra "Aún no hay publicaciones. ¡Sé el primero en publicar!"
    Y el botón "Publicar" sigue disponible

  Escenario 5: Sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando intenta cargar el Feed, cargar más, actualizar o abrir un detalle
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra el mensaje "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y las publicaciones que ya se veían se conservan
    Y si no había ninguna, aparece el botón "Reintentar"

  Escenario 6: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante carga el Feed o abre un detalle
    Entonces se muestra "No pudimos cargar las publicaciones. Inténtalo de nuevo."
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
    Y aparece el botón "Reintentar"

  Escenario 7: Ver el detalle de una publicación
    Dado que el estudiante está en el Feed
    Cuando toca una tarjeta (o "Ver publicación" en la confirmación de HU-03)
    Entonces ve todas las fotos en un carrusel con indicador "1 de N"
    Y ve el título, la descripción, la categoría, el precio o la modalidad, el estado
      y la fecha de publicación
    Y ve el nombre, la foto, la división y la carrera del dueño
    Y el botón "Contactar al vendedor" abre la pantalla "En desarrollo" (chat, Sprint 7)

  Escenario 8: Ver el detalle de mi propia publicación
    Dado que el estudiante abre el detalle de una publicación suya
    Entonces se muestra la etiqueta "Es tu publicación"
    Y no aparece "Contactar al vendedor"
    Y el botón "Gestionar publicación" abre la pantalla "En desarrollo" (Sprint 6)

  Escenario 9: Publicación reservada o vendida mientras se ve
    Dado que el estudiante abre el detalle de una publicación
    Cuando el dueño ya la marcó como "Reservado" o "Vendido"
    Entonces el detalle muestra el estado actualizado con el aviso:
      | Estado    | Aviso                                                     |
      | Reservado | Este artículo está reservado: el dueño ya está en trato.  |
      | Vendido   | Este artículo ya fue vendido.                             |
    Y el botón "Contactar al vendedor" queda deshabilitado
    Y al regresar al Feed, una publicación Vendida ya no aparece

  Escenario 10: Publicación eliminada mientras se ve
    Dado que el estudiante toca una publicación en el Feed
    Cuando el dueño ya la borró
    Entonces se muestra "Esta publicación ya no está disponible."
    Y el botón "Volver al Feed" lo regresa al Feed
    Y esa publicación desaparece de la lista
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- El Feed solo muestra publicaciones **Disponibles y Reservadas**, de la más nueva a la más vieja; páginas de **20** (la base no entrega más de 50 por petición).
- Solo estudiantes con sesión pueden ver el Feed y los detalles; un visitante sin cuenta no puede leer nada.
- Del dueño solo se muestran datos públicos de su perfil (nombre, foto, división y carrera); **nunca su correo**.
- El detalle siempre se vuelve a pedir al servidor al abrirlo, para no mostrar un estado viejo.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Ver el Feed | `obtener_feed_test` (primera página), `publicacion_model_test` (lee la vista con dueño y categoría), `feed_cubit_test` (cargar → Cargado), `publicaciones_api_rest_test` CP-20 (200 con la primera página, lleva el token) |
| 2. Cargar más | `obtener_feed_test` (manda el cursor de la última), `feed_cubit_test` (cargarMas agrega sin repetir; fin de la lista), CP-21 (siguiente página con cursor) |
| 3. Jalar para actualizar | `feed_cubit_test` (actualizar reemplaza la lista desde el inicio) |
| 4. Feed vacío | `feed_cubit_test` (lista vacía → Vacío), CP-22 (200 con `[]`) |
| 5. Sin conexión | `obtener_feed_test`, `obtener_detalle_publicacion_test`, `feed_cubit_test` (conserva la lista), `detalle_publicacion_cubit_test`, CP-26 (ninguna petición) |
| 6. Error del servidor | `feed_cubit_test`, `detalle_publicacion_cubit_test`, CP-25 (500 → mensaje genérico, sin IP ni nombres internos) |
| 7. Ver detalle | `obtener_detalle_publicacion_test`, `detalle_publicacion_cubit_test` (cargar → Cargado), CP-23 (200 con fotos y datos del dueño) |
| 8. Mi publicación | `detalle_publicacion_cubit_test` (esMia = true cuando el dueño es el usuario actual) |
| 9. Reservada o vendida | `estado_publicacion_test` (Reservado y Vendido no permiten contactar), `detalle_publicacion_cubit_test` (aviso por estado), `feed_cubit_test` (al actualizar ya no aparece la vendida) |
| 10. Eliminada | `obtener_detalle_publicacion_test` (fila vacía → no encontrada), `detalle_publicacion_cubit_test` (NoEncontrada), `feed_cubit_test` (quitar de la lista), CP-24 (200 con `[]` → "ya no está disponible") |

Otra prueba del API: CP-27 (sin sesión no se hace ninguna petición).

## 6. Definición de Hecho (Definition of Done) del Sprint 4

- [ ] Issue "HU-04: Feed de Publicaciones" creado en GitHub y vinculado al PR.
- [ ] Código en `feature/HU-04-feed-publicaciones`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261013120000_hu04_feed_publicaciones.sql` aplicada en Supabase y verificada: un visitante sin sesión no puede leer el Feed ni el detalle, y las Vendidas no salen en el Feed.
- [ ] Ya no aparece "En desarrollo" al tocar una tarjeta del Feed ni en "Ver publicación".
- [ ] Los 10 escenarios Gherkin de la sección 5 pasan manualmente contra el build (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01, HU-02 y HU-03.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info").
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, al menos 1 aprobación y CI en estado PASSED antes del merge (Squash and Merge). El PR menciona el issue de HU-04.
- [ ] Guía de diseño (`docs/Sprint4_Guia_Diseno.md`) entregada a Oziel.
- [ ] `develop` → `main` con la versión del Sprint 3 (y, si da tiempo, la del Sprint 4 después de la Review).
- [ ] Demo en la Sprint Review del viernes: login → Feed → scroll para cargar más → jalar para actualizar → abrir detalle (carrusel y dueño) → abrir una publicación propia → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Sprint corto y con entrega de seguridad el jueves 15:** el trabajo arrancó el martes 13 y Jesus tiene la entrega de la Unidad 2. Mitigación: la base de datos y la lógica se entregan el martes/miércoles para que pantallas y pruebas avancen en paralelo; si algo no alcanza (por ejemplo, el diseño final del Detalle), se mueve al Sprint 5 y se avisa en la Review.
- **No existe el issue del Feed en GitHub y la numeración no coincide:** el issue #1 dice "HU-04" pero es Mis Publicaciones. Mitigación: Oziel crea el issue de HU-04 el martes y en los documentos se usa la numeración del tablero mencionando el número de issue.
- **Publicaciones repetidas o saltadas al hacer scroll:** si alguien publica mientras otro hace scroll, paginar con "salta 20" repetiría artículos. Mitigación: paginación por **cursor** (fecha + id de la última publicación vista) en la función `feed_publicaciones`; probada con 60 publicaciones, 5 de ellas creadas en el mismo instante, y con páginas de 2 y de 7: ninguna repetida ni perdida.
- **Feed lento cuando crezca:** Mitigación: índice parcial `publicaciones_feed_cursor_idx` (solo Disponibles y Reservadas, por fecha e id). Con 20 000 publicaciones de prueba, cada página tarda unos 13 ms en la base.
- **Fotos pesadas en el carrusel y en la lista:** Mitigación: la lista usa solo la portada en tamaño reducido; el carrusel carga las fotos al deslizar.
- **Vista que saltara las reglas de seguridad:** en Postgres, una vista normal ignora el RLS. Mitigación: la vista se crea con `security_invoker = on`; se probó que si se quita la regla de lectura, la vista deja de regresar filas.
- **Diseño del Feed y del Detalle aún no está en Figma:** Mitigación: las pantallas se hacen con la paleta y los widgets compartidos y con Keys; Oziel ajusta lo visual en su rama sin tocar la lógica.
- **Choque con el diseño:** si Oziel y Luis Angel editan la misma pantalla, habrá conflictos. Mitigación: Oziel solo modifica `presentation/pages/`, `presentation/widgets/` y `core/theme/`, y siempre conserva las Keys.

## 8. Seguridad

HU-04 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **Mediación completa:** la vista corre con los permisos de quien la consulta, así que el RLS de `publicaciones`, `usuarios` y los catálogos se sigue aplicando.
- **Mínimo privilegio:** el rol `anon` (visitante sin cuenta) no puede leer la vista ni llamar la función; solo `authenticated`.
- **Minimización:** del dueño solo salen nombre, foto, división y carrera; nunca el correo.
- **Disponibilidad:** nadie puede pedir más de 50 publicaciones por petición.
- **Fallar de forma segura:** los errores llegan como mensajes en español sin detalles internos.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones).

## 9. Pendientes arrastrados del Sprint 3

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Confirmar con Servicios Escolares el acomodo carrera → división | Oziel y Jesus | Si cambia algo, Jonathan prepara una migración y Jose Luis la aplica | Pendiente |
| Validación manual de los casos de error de HU-01, HU-02 y HU-03 | Torres Valeriano Jesus | Checklist de validación con capturas | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | `chore/plataformas-flutter` (falta la carpeta `ios/`) | Pendiente |
| Ajustes visuales de "Publicar artículo" y la confirmación según Figma | Diaz Huerta Diego Oziel | Rama de diseño desde `develop` | Pendiente |
| Actividades de seguridad de la Unidad 2 (entrega jueves 15) | Torres Valeriano Jesus | Con `docs/Sprint3_Seguridad.md` | En curso |
| Pasar `develop` → `main` como versión del Sprint 3 (último merge a `main`: PR #22) | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |

**Orden sugerido de fusión a `develop`:** `feature/HU-04-feed-publicaciones` (base de datos, lógica, pantallas y pruebas) → ajustes de diseño de Oziel → `chore/plataformas-flutter` cuando esté lista la carpeta `ios/`. Después de la Review: `develop` → `main`.
