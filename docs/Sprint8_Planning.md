# Planeación del Sprint 8 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 8 |
| **Duración** | 1 semana (lunes 9 a viernes 13 de noviembre de 2026) |
| **Inicio real del trabajo** | Miércoles 11 de noviembre de 2026 (planeación, migración y pruebas de la base). El lunes 9 y el martes 10 no hubo cambios en el repositorio (el último commit en `develop` es del viernes 6) |
| **Fecha de cierre (Sprint Review)** | Viernes 13 de noviembre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-08-punto-encuentro` |
| **Issue de GitHub** | #3 (aparece como "HU-06: Coordinador de Puntos de Encuentro Seguros"; en los documentos y el tablero es **HU-08**). Está abierto |

> **Aviso para el Sprint 9:** el lunes 16 de noviembre es día de descanso obligatorio (aniversario de la Revolución). El Sprint 9 tendrá 4 días hábiles.

## 2. Sprint Goal

Dentro del chat, cualquiera de los dos estudiantes **propone un punto de encuentro oficial de la UTSJR** (por ejemplo, la entrada principal de la Biblioteca) con **día y hora**, y el otro lo **acepta o lo rechaza**. Al aceptarlo aparece una **tarjeta de confirmación** en el chat de los dos, al instante y con el globo de no leídos. La app y la base **no permiten lugares fuera del catálogo** ni horarios fuera de clases, nadie puede ver ni cambiar los encuentros de conversaciones ajenas, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-08** (PB-08, issue #3) | Punto de encuentro seguro | Baja (Could Have) | 5 pts |

> **Como** estudiante comprador u ofertante, **quiero** proponer y aceptar un punto de entrega oficial dentro de la universidad (por ejemplo Biblioteca, Edificio K o Cafetería), **para** hacer el intercambio físico de forma segura y convenida.

**Decisiones que deben confirmar los Product Owners (Oziel y Jesus) el jueves 12:**

| # | Pregunta | Recomendación del equipo de desarrollo | Por qué |
| :--- | :--- | :--- | :--- |
| 1 | ¿Quién puede **proponer**? | **Cualquiera de los dos** (comprador o vendedor). El **otro** acepta o rechaza; nadie acepta su propia propuesta. | La historia dice "comprador u ofertante". El escenario del issue (propone el vendedor, acepta el comprador) es un caso de esta regla. |
| 2 | ¿Qué lugares tiene el **catálogo**? | Lista inicial: **Biblioteca - Entrada Principal**, **Cafetería - Área de mesas**, **Edificio K - Planta baja**, **Explanada principal** y **Acceso principal - Vigilancia**. | Son lugares concurridos y vigilados. La lista vive en la base de datos: se puede cambiar sin tocar la app. **Falta confirmar los nombres exactos** con la universidad. |
| 3 | ¿En qué **horario** se puede quedar? | **Lunes a viernes de 7:00 a 20:00**, en horas exactas o medias horas, desde 30 minutos después de ahora y hasta **14 días** adelante. | Es cuando hay gente y vigilancia en el campus. Si los sábados hay clases, se agrega en la base con un cambio pequeño. |
| 4 | ¿Cuántos encuentros a la vez? | **Uno activo por conversación** (pendiente o confirmado). Para cambiarlo se rechaza o se cancela y se propone otro. | Evita confusiones sobre cuál es el lugar bueno. |
| 5 | ¿Quién puede **cancelar**? | Una propuesta pendiente: **solo quien la hizo** (el otro la rechaza). Un encuentro confirmado: **cualquiera de los dos**. | Cualquiera puede tener un imprevisto. |
| 6 | ¿Cuándo se puede proponer? | Con la **misma regla que escribir** en el chat: la publicación existe y **no está Vendida** (Reservada sí). | Es la regla de HU-07. Con una Reservada es justo cuando se coordina la entrega. |
| 7 | ¿Aceptar cambia la publicación a **Reservado**? | **No, automáticamente no.** El vendedor la marca en "Mis publicaciones" (HU-06). | Un encuentro no garantiza la venta; el vendedor decide. |
| 8 | ¿Cómo se **avisa a los dos**? | Con una **tarjeta en el chat** que llega al instante (tiempo real de HU-07), el **globo de no leídos** del Feed y la conversación que **sube en la bandeja**. En el chat, un **aviso fijo arriba** con el encuentro confirmado. | La notificación push con la app cerrada es de HU-10 (Sprint 10). |
| 9 | ¿Se puede escribir una **nota** o un lugar libre? | **No.** Solo se elige del catálogo, la fecha y la hora. | Así no se cuelan lugares fuera del campus (Escenario 2 del issue). Los detalles se platican en el chat. |

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Notificaciones push cuando la app está cerrada y recordatorios antes de la hora → **Sprint 10 (HU-10)**.
- Calificar al otro estudiante después del encuentro → **Sprint 9 (HU-09)**.
- Mapa del campus, ubicación GPS, "ya llegué" y pantalla para administrar el catálogo → backlog.

**Patrón de diseño:** **Factory Method** (el que pide el issue #3). Hay cuatro clases de solicitud de encuentro: **proponer, aceptar, rechazar y cancelar**. Cada una lleva datos y reglas distintas. Hay un **creador** por cada clase (`CreadorPropuesta`, `CreadorRespuesta`, `CreadorCancelacion`) con el mismo método `crear(...)`: revisa las reglas que se pueden revisar en el celular (lugar del catálogo, horario, que no sea tu propia propuesta) y fabrica la solicitud correcta. El Cubit solo pide "crea la solicitud" sin saber cuál es, y el repositorio la manda a la función que le toca en Supabase. Para agregar otra clase de solicitud (por ejemplo, "proponer otra hora") basta con un creador nuevo, sin tocar los demás.

Se eligió HU-08 porque, con el chat terminado, el siguiente paso de un trato es **verse para entregar el artículo**, y la universidad quiere que eso pase en lugares seguros del campus.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Confirmar las 9 decisiones de la sección 3 (sobre todo la lista de lugares) y validar los criterios Gherkin de HU-08 | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Actualizar el issue #3 con los criterios de la sección 5; cerrar el issue #2 (lo terminó el PR #35); cerrar #4, #5 y #6 y crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: catálogo `puntos_encuentro`, tabla `encuentros`, tipo de mensaje en `mensajes`, reglas RLS y funciones (proponer, responder, cancelar y encuentros de una conversación) | Cadena Vega Jonathan | Develop Team |
| Lógica: entidades, creadores de solicitudes (patrón Factory Method), validador de horario, casos de uso, modelos y repositorio | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de dominio y datos, y casos AAA del API REST simulado (CP-65 a CP-76) | Cadena Vega Jonathan | Develop Team |
| Estado: `EncuentrosCubit` (tarjetas y aviso fijo, escucha el tiempo real) y `PropuestaEncuentroCubit` (formulario) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas: botón "Proponer punto de encuentro" en el chat, hoja para elegir lugar, día y hora, tarjetas de encuentro y aviso fijo del encuentro confirmado, con Keys (`EncuentroKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de los Cubits (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño en Figma de la hoja y las tarjetas de encuentro y ajustes visuales en la rama | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar el Pull Request hacia `develop` (mínimo 1 aprobación registrada, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente HU-08 **con dos cuentas**, y el chat de HU-07 que quedó pendiente | Torres Valeriano Jesus | Product Owner / Validación |
| Aplicar en Supabase la migración de HU-08 **el mismo día** y comprobarla con la consulta del final del archivo (7 filas con "sí"); confirmar que la de HU-07 también está aplicada | Orduña Garrido Jose Luis | Scrum Master |
| Configurar la protección de `develop` para que exija 1 aprobación (lo hace Luis Angel, que es el dueño del repositorio) | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Scrum Master / Develop Team |
| Aprobar y fusionar el PR #29 `develop` → `main` | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 8, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-08

```gherkin
Historia: HU-08 Punto de encuentro seguro (issue #3)
Como estudiante comprador u ofertante
Quiero proponer y aceptar un punto de entrega oficial dentro de la universidad
Para hacer el intercambio físico de forma segura y convenida

  Escenario 1: Proponer un punto de encuentro
    Dado que dos estudiantes tienen una conversación sobre una publicación que no está Vendida
    Y no tienen un encuentro pendiente ni confirmado
    Cuando el vendedor presiona "Proponer punto de encuentro"
    Y elige "Biblioteca - Entrada Principal", un día y una hora permitidos
    Y presiona "Enviar propuesta"
    Entonces aparece en el chat de los dos una tarjeta "Propuesta de encuentro" con el lugar, el día y la hora
    Y al comprador le aparece al instante, sin refrescar, con los botones "Aceptar punto de encuentro" y "Rechazar"

  Escenario 2: Aceptar el punto de encuentro (escenario 1 del issue)
    Dado que el comprador ve la propuesta del vendedor
    Cuando presiona "Aceptar punto de encuentro"
    Entonces se genera en el chat una tarjeta de confirmación con el lugar, el día y la hora
    Y arriba del chat de los dos aparece fijo "Encuentro confirmado: Biblioteca - Entrada Principal, jueves 12 de noviembre, 13:00"
    Y al vendedor le llega al instante, sube el globo de mensajes sin leer del Feed y la conversación sube en su bandeja

  Escenario 3: Rechazar
    Dado que el estudiante ve una propuesta del otro
    Cuando presiona "Rechazar"
    Entonces la tarjeta cambia a "Rechazada"
    Y aparece en el chat "Rechazó la propuesta de vernos en <lugar>."
    Y los dos pueden proponer otro lugar

  Escenario 4: Cancelar
    Dado que hay una propuesta mía pendiente, o un encuentro confirmado
    Cuando presiono "Cancelar" y confirmo
    Entonces la tarjeta cambia a "Cancelada" para los dos
    Y desaparece el aviso fijo del encuentro confirmado
    Y los dos pueden proponer otro lugar

  Escenario 5: Lugar fuera del catálogo (escenario 2 del issue)
    Dado que el estudiante abre "Proponer punto de encuentro"
    Entonces solo puede elegir lugares del catálogo oficial de la UTSJR (no hay campo para escribir un lugar)
    Y si alguien envía otro lugar saltándose la app, el servidor lo rechaza
    Y se muestra "Solo se permiten zonas seguras dentro de la UTSJR."

  Escenario 6: Horario no permitido
    Dado que el estudiante elige el día y la hora
    Entonces solo puede elegir de lunes a viernes, de 7:00 a 20:00, cada media hora, desde dentro de 30 minutos y hasta 14 días adelante
    Y si alguien envía otro horario saltándose la app, el servidor lo rechaza
    Y se muestra "Elige un horario de lunes a viernes, de 7:00 a 20:00, dentro de los próximos 14 días."

  Escenario 7: Ya hay un encuentro activo
    Dado que la conversación tiene una propuesta pendiente o un encuentro confirmado
    Entonces el botón "Proponer punto de encuentro" está deshabilitado
    Y si alguien propone saltándose la app, el servidor lo rechaza
    Y se muestra "Ya hay un punto de encuentro pendiente o confirmado. Cancélalo o recházalo para proponer otro."

  Escenario 8: Mi propia propuesta
    Dado que yo hice la propuesta
    Entonces mi tarjeta dice "Esperando respuesta" y solo tiene el botón "Cancelar propuesta"
    Y si intento aceptarla saltándome la app, el servidor lo rechaza

  Escenario 9: Propuesta vencida
    Dado que nadie respondió una propuesta y ya pasó la hora
    Entonces la tarjeta dice "Venció" y no tiene botones
    Y si alguien intenta aceptarla, se muestra "La hora propuesta ya pasó. Propongan otra."
    Y se puede proponer otro lugar

  Escenario 10: Conversación cerrada
    Dado que la publicación se marcó como Vendida o se borró
    Cuando el estudiante abre la conversación
    Entonces puede ver las tarjetas de encuentro, pero sin botones
    Y no aparece "Proponer punto de encuentro"
    Y si alguien lo intenta saltándose la app, el servidor lo rechaza

  Escenario 11: Conversación ajena
    Dado que una conversación es entre otros dos estudiantes
    Cuando un tercero intenta ver, proponer, aceptar, rechazar o cancelar sus encuentros saltándose la app
    Entonces el servidor no le muestra nada y rechaza la acción
    Y nadie puede fabricar una tarjeta de encuentro mandando un mensaje directo

  Escenario 12: Demasiados mensajes
    Dado que el estudiante envió 20 mensajes o propuestas en menos de un minuto
    Cuando intenta proponer, aceptar, rechazar o cancelar
    Entonces se muestra "Estás enviando muchos mensajes. Espera un momento."
    Y la hoja conserva el lugar, el día y la hora que eligió

  Escenario 13: Sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Cuando el estudiante intenta proponer, responder o cancelar
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y la hoja conserva lo que eligió

  Escenario 14: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante propone, responde, cancela o se cargan las tarjetas
    Entonces se muestra "No pudimos completar la acción. Inténtalo de nuevo."
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- El catálogo solo tiene lugares oficiales dentro de la UTSJR; no hay lugares escritos a mano.
- Cualquiera de los dos propone; el otro acepta o rechaza. Nadie responde su propia propuesta.
- Horario: lunes a viernes, de 7:00 a 20:00 (hora del centro de México), cada media hora, de 30 minutos a 14 días adelante.
- Un solo encuentro activo (pendiente o confirmado) por conversación.
- Cancelar: la propuesta, quien la hizo; el confirmado, cualquiera de los dos.
- Se puede proponer y responder mientras la publicación exista y no esté Vendida.
- Cada propuesta o respuesta cuenta como mensaje para el límite de 20 por minuto.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Proponer | `creadores_solicitud_test` (CreadorPropuesta), `casos_de_uso_encuentros_test`, `propuesta_encuentro_cubit_test`, `encuentros_cubit_test` (la tarjeta llega por el `Stream`), CP-66 (POST `rpc/proponer_encuentro` → 200 con el id); SQL 6 y 7 |
| 2. Aceptar | `creadores_solicitud_test` (CreadorRespuesta), `encuentros_cubit_test` (aviso fijo y tarjeta de confirmación), CP-70 (POST `rpc/responder_encuentro`); SQL 15, 18, 19 y 21 |
| 3. Rechazar | `encuentros_cubit_test`, CP-70; SQL 47 |
| 4. Cancelar | `creadores_solicitud_test` (CreadorCancelacion), `encuentros_cubit_test`, CP-72; SQL 34 y 35 |
| 5. Fuera del catálogo | `creadores_solicitud_test` (no llama al servidor), `modelos_encuentro_test` (catálogo), CP-65 (GET `puntos_encuentro`), CP-67 (400 `punto_no_permitido`); SQL 2, 3 y 36 a 38 |
| 6. Horario | `horario_encuentro_test`, `propuesta_encuentro_cubit_test`, CP-68 (400 `horario_no_permitido`); SQL 39 a 46 |
| 7. Encuentro activo | `encuentro_test` (`hayActivo`), `encuentros_cubit_test`, CP-69 (400 `encuentro_activo`); SQL 8 y 24 |
| 8. Propia | `encuentro_test` (qué botones tiene), `creadores_solicitud_test`, CP-71 (400 `encuentro_propio`); SQL 9 y 16 |
| 9. Vencida | `encuentro_test`, CP-71 (400 `encuentro_vencido`); SQL 49 a 51 |
| 10. Cerrada | `encuentros_cubit_test`, CP-75 (400 `conversacion_cerrada`); SQL 52 a 56 |
| 11. Ajena | CP-74 (42501 → sin permiso); SQL 10 a 14, 17 y 25 a 33 |
| 12. Demasiados | `propuesta_encuentro_cubit_test` (conserva lo elegido), CP-75 (400 `demasiados_mensajes`); SQL 57 y 58 |
| 13. Sin conexión | todos los casos de uso, los dos Cubits, CP-76 (ninguna petición) |
| 14. Error del servidor | los dos Cubits, CP-76 (500 → mensaje genérico) |

**Pruebas de la base de datos:** la migración se probó el miércoles 11 en un Postgres 16 local con el stub de Auth, Storage y Realtime, encima de las 8 migraciones anteriores, y corrida **dos veces** (es idempotente): **63 casos, todos pasan**. Entre ellos, un tercer estudiante **no puede ver** los encuentros ni las tarjetas de una conversación ajena, **no puede proponer, aceptar, rechazar ni cancelar** en ella, y nadie puede cambiar un encuentro directamente ni fabricar una tarjeta con un mensaje directo. También siguen funcionando el chat, la bandeja y los no leídos de HU-07.

## 6. Definición de Hecho (Definition of Done) del Sprint 8

- [ ] Las 9 decisiones de la sección 3 confirmadas por los Product Owners; issue #3 actualizado con estos criterios.
- [ ] Código en `feature/HU-08-punto-encuentro`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261111120000_hu08_punto_encuentro.sql` aplicada en Supabase **el mismo día** y comprobada con la consulta del final del archivo (7 filas con "sí").
- [ ] Los 14 escenarios Gherkin de la sección 5 pasan manualmente con dos cuentas (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 a HU-07.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info").
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, **al menos 1 aprobación registrada** y CI en estado PASSED antes del merge. El PR menciona el issue #3 (`Closes #3`).
- [ ] Anexo de CP-65 a CP-76 en `docs/Plan_de_Pruebas.md`.
- [ ] Guía de diseño (`docs/Sprint8_Guia_Diseno.md`) entregada a Oziel.
- [ ] Demo en la Sprint Review: dos cuentas → chat → el vendedor propone "Biblioteca - Entrada Principal" y una hora → al comprador le llega al instante → "Aceptar punto de encuentro" → tarjeta de confirmación y aviso fijo en los dos → intentar proponer otro (deshabilitado) → cancelar → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Sprint de tres días:** el trabajo empezó el miércoles 11 y la Review es el viernes 13. Mitigación: la base de datos ya está probada el miércoles. Si el aviso fijo o la cancelación no alcanzan, se entrega lo demás (proponer, aceptar, rechazar y la tarjeta de confirmación, que son los dos escenarios del issue) y lo que falte pasa al Sprint 9, avisándolo en la Review.
- **Decisiones sin confirmar:** si los Product Owners cambian la lista de lugares o el horario el jueves, solo cambian datos en la migración (la lista y una función), no la app.
- **Nombres de lugares:** los de la lista son una propuesta del equipo. Mitigación: Oziel y Jesus los confirman; mientras, se usan como datos de prueba.
- **Zona horaria:** un celular con la hora mal configurada podría ofrecer horarios inválidos. Mitigación: la base revisa el horario con la hora del centro de México y la app muestra el mensaje del Escenario 6.
- **Tiempo real:** las tarjetas llegan por el mismo WebSocket del chat. Si Realtime no está encendido, aparecen al volver a abrir el chat (riesgo ya cubierto en HU-07).
- **Migración de HU-07 sin confirmar:** HU-08 la necesita. Mitigación: José Luis corre primero la consulta de comprobación de HU-07 (4 filas con "sí").
- **Fusiones sin aprobación:** el PR #35 se fusionó sin aprobación y `develop` sigue sin protección. Mitigación: Luis Angel la configura antes de abrir el PR de HU-08.

## 8. Seguridad

HU-08 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **Mínimo privilegio:** solo los dos participantes ven los encuentros (RLS). Los encuentros solo se crean y cambian con las funciones `proponer_encuentro`, `responder_encuentro` y `cancelar_encuentro`, que revisan todas las reglas con el estudiante de la sesión. Nadie puede escribir directo en `encuentros` ni en el catálogo. El rol `anon` no tiene acceso.
- **No confiar en el cliente:** quién propone o responde sale de la sesión; el lugar se busca en el catálogo de la base; el horario lo revisa la base. Un mensaje directo no puede hacerse pasar por tarjeta de encuentro.
- **Lugares seguros:** no hay texto libre para el lugar ni notas; así no se cuelan direcciones fuera del campus ni datos personales.
- **Tiempo real con las mismas reglas:** las tarjetas llegan como mensajes, y Realtime respeta RLS.
- **Disponibilidad:** un encuentro activo por conversación, 50 encuentros por petición y el límite de 20 mensajes por minuto también cuenta las propuestas.
- **Errores sin detalles internos:** cada rechazo trae una pista fija y la app muestra un mensaje claro.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones).

## 9. Pendientes arrastrados del Sprint 7

Estado revisado en GitHub el miércoles 11 de noviembre:

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| El PR #35 (chat) se fusionó el viernes 6 **sin aprobación registrada** y sin `Closes #2`: el issue #2 sigue abierto | Diaz Huerta Diego Oziel | Cerrar el #2 a mano con un comentario que mencione el PR #35 | Pendiente |
| Configurar la protección de `develop` (hoy **no tiene protección**) | Gonzalez Casarrubias Luis Angel (dueño) y Orduña Garrido Jose Luis | Settings → Branches → regla para `develop` con 1 aprobación | Pendiente |
| Aprobar y fusionar el PR #29 `develop` → `main` (abierto desde el 9 de octubre, hoy con 62 commits; GitHub lo marca **bloqueado**: le falta la aprobación que pide `main`) | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |
| Ordenar los issues: cerrar #4, #5 y #6 (historias ya terminadas) y crear el issue "HU-04: Feed de Publicaciones". También siguen abiertos el #7 (repositorio y CI) y el #8 (caso de estudio) del Sprint 0 | Diaz Huerta Diego Oziel | GitHub Issues | Pendiente |
| Confirmar que la migración del chat (`20261106120000_hu07_chat.sql`) está aplicada y validar el chat con dos cuentas | Orduña Garrido Jose Luis y Torres Valeriano Jesus | Consulta del final del archivo y checklist | Por confirmar |
| Diseño en Figma del chat y de las pantallas de HU-05 y HU-06 | Diaz Huerta Diego Oziel | Rama de diseño desde `develop` | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | Sigue sin existir la carpeta `app/ios/` | Pendiente |
| Cargar publicaciones de prueba de varias carreras | Cadena Vega Jonathan | Datos de prueba en Supabase | Pendiente |
| Confirmar con Servicios Escolares el acomodo carrera → división | Oziel y Jesus | Si cambia algo, Jonathan prepara una migración | Pendiente |

**Orden sugerido de fusión a `develop`:** `feature/HU-08-punto-encuentro` → ajustes de diseño de Oziel. Después de la Review: `develop` → `main`.
