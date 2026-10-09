# Planeación del Sprint 3 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 3 |
| **Duración** | 1 semana (lunes 5 a viernes 9 de octubre de 2026) |
| **Inicio real del trabajo** | Miércoles 7 de octubre de 2026 (el Sprint 2 cerró el martes 6) |
| **Fecha de cierre (Sprint Review)** | Viernes 9 de octubre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-03-publicar-articulo` |
| **Issue de GitHub** | #4 (aparece como "HU-02: Publicación de Artículo Académico"; en los documentos y el tablero es **HU-03**) |

## 2. Sprint Goal

Un estudiante con su perfil completo puede **publicar un artículo académico** desde el Feed: escribe título y descripción, elige categoría y modalidad (Venta, Intercambio o Gratis), agrega de 1 a 5 fotos y, si es venta, su precio. La publicación queda **guardada en Supabase a su nombre, en estado Disponible y protegida** para que nadie más pueda cambiarla, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-03** (PB-03, issue #4) | Publicación de Artículo Académico | Alta | 8 pts |

> **Como** estudiante universitario autenticado, **quiero** publicar un artículo académico (libro, bata, calculadora) indicando imágenes, categoría y modalidad (Venta, Intercambio o Gratis), **para** ponerlo a disposición de otros compañeros de la universidad.

**Patrón de diseño:** State. Cada publicación tiene un ciclo de vida: **Disponible → Reservado → Vendido**. Cada estado decide qué cambios se permiten (por ejemplo, una publicación Vendida ya no puede volver a Disponible). En este sprint toda publicación nace en Disponible; los cambios de estado se usarán en los siguientes sprints (reservar desde el chat, marcar como vendido).

Se eligió HU-03 porque sin publicaciones no hay marketplace: el Feed, el filtrado por división y carrera, y el chat dependen de que existan artículos publicados. HU-02 ya deja a cada estudiante identificado con su división y carrera, así que este es el siguiente paso natural.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Base de datos: catálogo de categorías, tabla `publicaciones` (fotos, modalidad, precio, estado y dueño), reglas de seguridad (RLS) y bucket de fotos `publicaciones` | Cadena Vega Jonathan | Develop Team |
| Lógica: entidades, estados de la publicación (patrón State), validaciones, casos de uso y repositorio contra Supabase | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de validaciones y casos de uso, y pruebas del API REST simulado con patrón AAA (`publicaciones_api_rest_test`) | Cadena Vega Jonathan | Develop Team |
| Estado y navegación: `PublicacionCubit`, ruta `/publicar` y botón "Publicar" en el Feed | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantalla "Publicar artículo" con la paleta del logo y los widgets compartidos, usando Keys (`PublicacionKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas del `PublicacionCubit` (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Permiso de galería en iPhone (`ios/Runner/Info.plist`), en cuanto exista la carpeta `ios/` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Definir y validar los criterios de aceptación (Gherkin) de HU-03 | Diaz Huerta Diego Oziel | Product Owner |
| Diseño de la pantalla "Publicar artículo" en Figma y ajustes visuales en la rama | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Conseguir el catálogo oficial de Divisiones y Carreras de la UTSJR | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 revisor, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente los escenarios de HU-03 y los casos de error pendientes de HU-01 y HU-02 contra el build | Torres Valeriano Jesus | Product Owner / Validación |
| Actividades de seguridad de la Unidad 2, Tema 1 (recolección de datos, auditoría de vulnerabilidades y matriz de seguridad), con el insumo `docs/Sprint3_Seguridad.md`; entrega el jueves 15 de octubre | Torres Valeriano Jesus | Product Owner / Validación |
| Aplicar la migración de HU-03 en Supabase (y el catálogo oficial cuando llegue) | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 3, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-03

```gherkin
Historia: HU-03 Publicación de Artículo Académico (issue #4)
Como estudiante universitario autenticado
Quiero publicar un artículo académico (libro, bata, calculadora) indicando imágenes, categoría y modalidad
Para ponerlo a disposición de otros compañeros de la universidad

  Escenario 1: Publicar un artículo en Intercambio o Gratis
    Dado que el estudiante inició sesión y su perfil está completo
    Y está en la pantalla "Publicar artículo"
    Cuando escribe el título y la descripción, elige una categoría
    Y agrega al menos una foto JPG o PNG
    Y elige la modalidad "Intercambio" o "Gratis"
    Y presiona "Publicar artículo"
    Entonces la API responde 201 Created
    Y la publicación queda asignada al estudiante y en estado "Disponible"
    Y el estudiante es dirigido al Feed principal

  Escenario 2: Venta sin precio
    Dado que el estudiante está en la pantalla "Publicar artículo"
    Y eligió la modalidad "Venta"
    Cuando deja el precio vacío y presiona "Publicar artículo"
    Entonces el sistema no envía la publicación
    Y el campo de precio se marca en rojo con el mensaje "Debe especificar un costo para la modalidad Venta"

  Escenario 3: Venta con precio en cero
    Dado que el estudiante eligió la modalidad "Venta"
    Cuando escribe un precio de 0 y presiona "Publicar artículo"
    Entonces el sistema no envía la publicación
    Y el campo de precio se marca en rojo con el mensaje "El precio debe ser mayor a $0."

  Escenario 4: Foto mayor a 5 MB
    Dado que el estudiante está en la pantalla "Publicar artículo"
    Cuando elige una foto que pesa más de 5 MB
    Entonces el sistema no agrega esa foto
    Y se muestra el mensaje "Cada foto puede pesar máximo 5 MB."
    Y las fotos y datos que ya había capturado se conservan

  Escenario 5: Campos obligatorios vacíos
    Dado que el estudiante está en la pantalla "Publicar artículo"
    Cuando presiona "Publicar artículo" sin título, sin descripción, sin categoría, sin modalidad o sin fotos
    Entonces el sistema no envía la publicación
    Y cada campo faltante muestra su mensaje:
      | Campo       | Mensaje                                         |
      | Título      | Escribe un título de 3 a 80 caracteres.         |
      | Descripción | Escribe una descripción de 10 a 500 caracteres. |
      | Categoría   | Elige una categoría.                            |
      | Modalidad   | Elige una modalidad.                            |
      | Fotos       | Agrega al menos una foto.                       |

  Escenario 6: Sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando presiona "Publicar artículo" con todos los datos correctos
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra el mensaje "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y los datos y fotos que ya había capturado se conservan
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- Cada foto: JPG o PNG de máximo 5 MB. Mínimo 1 y máximo 5 fotos por publicación.
- En **Venta** el precio es obligatorio y mayor a $0. En **Intercambio** y **Gratis** no se guarda precio.
- Toda publicación nace en estado **Disponible** y queda a nombre de quien la crea.
- Solo el dueño puede editar o borrar su publicación; cualquier estudiante autenticado puede verla.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Publicar en Intercambio o Gratis | `crear_publicacion_test` (Escenario 1), `publicacion_cubit_test` (publicar → Publicada), `estado_publicacion_test` (nace Disponible), `publicaciones_api_rest_test` CP-09 (fotos a Storage + POST → 201 Created a nombre del alumno y Disponible) |
| 2. Venta sin precio | `publicacion_validator_test`, `crear_publicacion_test` (Escenario 2), `publicacion_cubit_test` (error en el campo precio), `publicaciones_api_rest_test` CP-10 (no se envía nada); además la base de datos lo bloquea |
| 3. Venta con precio en cero | `publicacion_validator_test`, `publicaciones_api_rest_test` CP-11 (si alguien salta la app, el API responde 400); además la base de datos lo bloquea |
| 4. Foto mayor a 5 MB | `publicacion_validator_test`, `subir_fotos_publicacion_test`, `crear_publicacion_test` (Escenario 4), `publicacion_cubit_test` (agregarFotos), `publicaciones_api_rest_test` CP-14 (Storage responde 413); además el bucket rechaza archivos de más de 5 MB |
| 5. Campos obligatorios | `publicacion_validator_test`, `crear_publicacion_test` (Escenario 5), `publicacion_cubit_test` (errores por campo) |
| 6. Sin conexión | `crear_publicacion_test` (Escenario 6), `obtener_categorias_test`, `subir_fotos_publicacion_test`, `publicacion_cubit_test` (conserva los datos), `publicaciones_api_rest_test` CP-15 (no hay ninguna petición) |

Otras pruebas del API: CP-08 (catálogo de categorías), CP-12 (si falla el guardado se borran las fotos subidas), CP-13 (403 con perfil incompleto), CP-16 (sin sesión no hay peticiones) y CP-17 (errores sin detalles internos).

## 6. Definición de Hecho (Definition of Done) del Sprint 3

- [ ] Código en `feature/HU-03-publicar-articulo`, con commits siguiendo Conventional Commits.
- [ ] Migración aplicada en Supabase y verificada: un usuario no puede crear publicaciones a nombre de otro, ni editar o borrar publicaciones ajenas, ni subir fotos fuera de su carpeta.
- [ ] Los 6 escenarios Gherkin de la sección 5 pasan manualmente contra el build (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 y HU-02.
- [ ] `flutter analyze` sin errores ni advertencias.
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, al menos 1 aprobación y CI en estado PASSED antes del merge (Squash and Merge). El PR menciona el issue #4.
- [ ] Guía de diseño (`docs/Sprint3_Guia_Diseno.md`) entregada a Oziel.
- [ ] Insumo de seguridad (`docs/Sprint3_Seguridad.md`) entregado a Jesus.
- [ ] Demo en la Sprint Review del viernes: login → Feed → Publicar artículo (Venta sin precio muestra el error) → publicar en Intercambio → regreso al Feed.

## 7. Riesgos específicos del sprint

- **Sprint corto:** el trabajo real empezó el miércoles 7, así que hay 3 días en lugar de 5. Mitigación: la base de datos y la lógica se entregan primero (miércoles) para que la pantalla y las pruebas avancen en paralelo; si algo no alcanza, se mueve al Sprint 4 y se avisa en la Review.
- **Publicación sin fotos o con fotos a medias:** si se suben las fotos y falla el guardado, quedan archivos sueltos en Storage. Mitigación: primero se validan todos los datos en la app; las fotos y la publicación se envían al final, y si el guardado falla se borran las fotos recién subidas.
- **Fotos grandes desde el celular:** las cámaras actuales sacan fotos de más de 5 MB. Mitigación: la app pide a la galería una copia más ligera (máx. 1920 px, calidad 85) y, si aun así pesa más, muestra el mensaje del Escenario 4.
- **Catálogo de categorías:** la migración trae una lista inicial (Libros, Calculadoras, Batas y uniformes, etc.). Mitigación: vive en una tabla, así que el Product Owner puede cambiarla en Supabase sin tocar la app.
- **Migración de la base de datos:** agrega tablas y un bucket nuevos, sin tocar `usuarios`. Mitigación: se puede correr varias veces sin romper nada.
- **Choque con el diseño:** si Oziel y Luis Angel editan la misma pantalla, habrá conflictos. Mitigación: Oziel solo modifica `presentation/pages/`, `presentation/widgets/` y `core/theme/`, y siempre conserva las Keys.

## 8. Seguridad (Unidad 2, Tema 1: codificación segura)

Esta semana la profesora asignó tres actividades de seguridad (entrega individual en PDF el jueves 15 de octubre). Las arma Jesus con el insumo `docs/Sprint3_Seguridad.md`. HU-03 ya aplica estos principios, marcados en el código con el comentario `SEGURIDAD:`:

- **No confiar en el cliente:** la app no envía el dueño ni el estado; la base los asigna y vuelve a revisar precio, fotos y textos.
- **Mínimo privilegio y mediación completa:** reglas RLS en cada petición; cada estudiante solo escribe en sus filas y en su carpeta de fotos.
- **Fallar de forma segura:** si algo falla no queda nada a medias y el mensaje no revela detalles internos.
- **Validación de entrada:** longitud, formato y rango; las fotos se validan por su firma, no por la extensión.

Vulnerabilidades detectadas que quedan para sprints posteriores: validación del dominio institucional solo en la app (V1), fotos públicas con posibles metadatos de ubicación (V2) y sesión sin cifrar en el celular (V3).

## 9. Pendientes arrastrados del Sprint 2

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Catálogo oficial de Divisiones y Carreras (hoy es *PROVISIONAL*) | Oziel y Jesus (conseguirlo), Jose Luis (aplicarlo en Supabase) | Sin cambios en la app; se actualizan las tablas `divisiones` y `carreras` | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription` en `ios/Runner/Info.plist`); ahora lo necesitan HU-02 y HU-03 | Gonzalez Casarrubias Luis Angel | `chore/plataformas-flutter` (falta la carpeta `ios/` en el repo) | Pendiente |
| Validar manualmente los casos de error de HU-01 (correo no institucional, credenciales incorrectas, sin conexión) y de HU-02 (carrera fuera de la división, foto mayor a 5 MB, sin conexión) | Torres Valeriano Jesus | Checklist de validación | Pendiente |

**Orden sugerido de fusión a `develop`:** `feature/HU-03-publicar-articulo` (base de datos, lógica, pantalla y pruebas) → ajustes de diseño de Oziel → `chore/plataformas-flutter` cuando esté lista la carpeta `ios/`.
