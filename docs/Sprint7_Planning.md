# Planeación del Sprint 7 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 7 |
| **Duración** | 1 semana (lunes 2 a viernes 6 de noviembre de 2026; el lunes 2 fue Día de Muertos) |
| **Inicio real del trabajo** | Viernes 6 de noviembre de 2026 (planeación, migración y código). Entre el lunes 2 y el jueves 5 no hubo cambios en el repositorio |
| **Fecha de cierre (Sprint Review)** | Viernes 6 de noviembre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-07-chat` |
| **Issue de GitHub** | #2 (aparece como "HU-05: Chat Interno en Tiempo Real"; en los documentos y el tablero es **HU-07**). Está abierto |

## 2. Sprint Goal

Un estudiante con sesión iniciada **le escribe al vendedor** desde el detalle de una publicación y los dos **conversan dentro de la app en tiempo real**, sin compartir su teléfono ni su correo. Cada uno tiene una **bandeja de mensajes** con sus conversaciones y un **aviso de mensajes sin leer**. Nadie puede leer ni escribir en conversaciones ajenas, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-07** (PB-07, issue #2) | Chat directo entre interesado y vendedor | Media (Should Have) | 8 pts |

> **Como** estudiante interesado en un artículo, **quiero** enviar mensajes directos al vendedor desde la pantalla del producto, **para** coordinar dudas, precio o detalles del trueque sin exponer mis datos personales.

**Decisiones que deben confirmar los Product Owners (Oziel y Jesus) el viernes 6:**

| # | Pregunta | Recomendación del equipo de desarrollo | Por qué |
| :--- | :--- | :--- | :--- |
| 1 | ¿Cuándo se puede **iniciar** una conversación? | Solo si la publicación está **Disponible**, **no es mía** y mi **perfil está completo**. Si ya existe una conversación, "Contactar" la abre. | Es la regla de HU-06: "Reservado" deshabilita "Contactar" para nuevos interesados. Pedir el perfil completo es lo mismo que para publicar. |
| 2 | ¿Se puede seguir escribiendo si la publicación cambia de estado? | **Reservada: sí.** **Vendida o borrada: solo lectura.** | Con una Reservada, comprador y vendedor siguen coordinando la entrega. Vendido significa que la entrega ya se hizo. |
| 3 | ¿Qué caracteres se aceptan en los mensajes? | La **misma lista que la descripción**: letras, números, signos comunes y saltos de línea, **sin emojis**. Entre 1 y 500 caracteres. | Sigue la observación de la docente sobre los caracteres especiales y usa la regla que ya existe. |
| 4 | ¿Se pueden editar o borrar mensajes o conversaciones? | **No** en este sprint. | Evita confusiones en un trato, y la reputación (HU-09) podrá revisar la conversación. |
| 5 | ¿Dónde está la bandeja de mensajes? | Un **ícono de mensajes en el encabezado del Feed**, junto a la foto de perfil, con un **globo** que dice cuántas conversaciones tienen mensajes sin leer. | Es lo primero que ve el estudiante al abrir la app. |
| 6 | ¿Hay un límite de mensajes? | **20 por minuto por estudiante.** | Evita el spam (relacionado con la vulnerabilidad V5). |

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Notificaciones push cuando la app está cerrada → **Sprint 10 (HU-10)**.
- Proponer un punto de encuentro desde el chat → **Sprint 8 (HU-08)**.
- Calificar al otro estudiante → **Sprint 9 (HU-09)**.
- Enviar fotos, indicador de "escribiendo…", palomitas de leído por mensaje, bloquear o reportar usuarios y borrar conversaciones → backlog.

**Patrón de diseño:** **Observer** (el que pide el issue #2). La capa de datos se suscribe por **WebSocket** a los mensajes nuevos de Supabase Realtime y los publica como un `Stream`. El chat y la bandeja son los **observadores**: cuando llega un mensaje, se actualizan solos, sin refrescar la pantalla. Al salir de la pantalla, cancelan su suscripción.

Se eligió HU-07 porque el botón "Contactar al vendedor" del Detalle abre "En desarrollo" desde el Sprint 4, y sin chat no se puede concretar ningún trato. El estado "Reservado" de HU-06 ya está listo para usarse aquí.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Confirmar las 6 decisiones de la sección 3 y validar los criterios de aceptación (Gherkin) de HU-07 | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Actualizar el issue #2 con los criterios de la sección 5; cerrar los issues #4, #5 y #6 (historias ya terminadas) y crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: tablas `conversaciones` y `mensajes`, reglas RLS, funciones (iniciar, bandeja, mensajes por páginas, marcar como leída, no leídos), límite contra el spam y mensajes en tiempo real | Cadena Vega Jonathan | Develop Team |
| Lógica: entidades, casos de uso, modelo, repositorio y suscripción en tiempo real (patrón Observer) | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias y casos AAA del API REST simulado (CP-53 a CP-64) | Cadena Vega Jonathan | Develop Team |
| Estado y navegación: `ChatCubit` y `BandejaCubit`; rutas `/chat` y `/mensajes`; quitar el "En desarrollo" de "Contactar al vendedor" | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas: "Chat" (burbujas, campo de texto, historial hacia arriba, avisos) y "Mensajes" (bandeja con globos de no leídos), con la paleta del logo y Keys (`ChatKeys`, `BandejaKeys`); ícono de mensajes en el Feed | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de los Cubits (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Permiso de galería en iPhone (`ios/Runner/Info.plist`), en cuanto exista la carpeta `ios/` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño del chat y la bandeja en Figma y ajustes visuales en la rama | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 aprobación registrada, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente HU-07 **con dos celulares o dos cuentas** y los casos pendientes de HU-06 | Torres Valeriano Jesus | Product Owner / Validación |
| Aplicar en Supabase la migración de HU-07 **el mismo día** y comprobarla con la consulta del final del archivo; confirmar que la de caracteres permitidos (Sprint 6) también esté aplicada | Orduña Garrido Jose Luis | Scrum Master |
| Configurar la protección de `develop` para que exija 1 aprobación | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Scrum Master / Develop Team |
| Aprobar y fusionar el PR #29 `develop` → `main` | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 7, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-07

```gherkin
Historia: HU-07 Chat directo (issue #2)
Como estudiante interesado en un artículo
Quiero enviar mensajes directos al vendedor desde la pantalla del producto
Para coordinar dudas, precio o detalles del trueque sin exponer mis datos personales

  Escenario 1: Contactar al vendedor
    Dado que el estudiante ve el detalle de una publicación Disponible de otro estudiante
    Y su perfil está completo
    Cuando presiona "Contactar al vendedor"
    Entonces se abre el chat con el título y la foto de la publicación y el nombre del vendedor
    Y si es la primera vez se muestra "Escríbele al vendedor para ponerse de acuerdo."

  Escenario 2: Contactar de nuevo
    Dado que el estudiante ya había escrito sobre esa publicación
    Cuando vuelve a presionar "Contactar al vendedor"
    Entonces se abre la misma conversación con sus mensajes anteriores

  Escenario 3: Enviar y recibir en tiempo real
    Dado que dos estudiantes tienen abierta la conversación de una publicación
    Cuando el interesado escribe un mensaje y presiona "Enviar"
    Entonces el mensaje aparece en su pantalla
    Y aparece de inmediato en la pantalla del vendedor, sin refrescar la vista
    Y la conversación sube al primer lugar de la bandeja de los dos

  Escenario 4: Publicación propia
    Dado que el estudiante ve el detalle de su propia publicación
    Entonces no aparece "Contactar al vendedor"
    Y aparece "Gestionar publicación"

  Escenario 5: Publicación Reservada o Vendida
    Dado que la publicación está Reservada o Vendida
    Cuando otro estudiante que no la había contactado ve su detalle
    Entonces "Contactar al vendedor" está deshabilitado
    Y si alguien intenta iniciar la conversación saltándose la app, el servidor la rechaza

  Escenario 6: Perfil incompleto
    Dado que el estudiante no ha completado su perfil
    Cuando presiona "Contactar al vendedor"
    Entonces se muestra "Completa tu perfil para poder contactar al vendedor."
    Y no se crea ninguna conversación

  Escenario 7: Bandeja de mensajes
    Dado que el estudiante tiene conversaciones
    Cuando toca el ícono de mensajes del Feed
    Entonces ve sus conversaciones, la más reciente primero
    Y cada una muestra la foto y el título de la publicación, el nombre del otro estudiante,
      el último mensaje y cuántos mensajes no ha leído
    Y si no tiene conversaciones se muestra "Aún no tienes mensajes."

  Escenario 8: Mensajes sin leer
    Dado que el estudiante recibió mensajes que no ha leído
    Entonces el ícono de mensajes del Feed muestra un globo con el número de conversaciones pendientes
    Cuando abre la conversación
    Entonces los mensajes quedan como leídos y el globo baja

  Escenario 9: Historial
    Dado que la conversación tiene más de 30 mensajes
    Cuando el estudiante sube hasta el principio
    Entonces se cargan los 30 anteriores sin repetir ninguno

  Escenario 10: Mensaje inválido
    Dado que el estudiante está en el chat
    Cuando el mensaje está vacío o tiene más de 500 caracteres
    Entonces el botón "Enviar" está deshabilitado
    Y el campo no deja escribir caracteres no permitidos (por ejemplo < > ; " o emojis)
    Y si alguien los envía saltándose la app, el servidor los rechaza

  Escenario 11: Conversación cerrada
    Dado que la publicación se marcó como Vendida o se borró
    Cuando el estudiante abre la conversación
    Entonces puede leer los mensajes
    Y en lugar del campo de texto se muestra "Esta publicación ya no está disponible. Puedes leer la conversación, pero ya no enviar mensajes."

  Escenario 12: Conversación ajena
    Dado que una conversación es entre otros dos estudiantes
    Entonces no aparece en su bandeja
    Y si intenta leerla o escribir en ella saltándose la app, el servidor no le muestra nada y rechaza el mensaje

  Escenario 13: Demasiados mensajes
    Dado que el estudiante envió 20 mensajes en menos de un minuto
    Cuando intenta enviar otro
    Entonces se muestra "Estás enviando muchos mensajes. Espera un momento."
    Y el texto que escribió se conserva

  Escenario 14: Sin conexión
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando intenta abrir el chat, la bandeja o enviar un mensaje
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y el texto que escribió se conserva

  Escenario 15: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante abre el chat, la bandeja o envía un mensaje
    Entonces se muestra "No pudimos completar la acción. Inténtalo de nuevo."
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- Una conversación por publicación y por interesado; solo la ven sus dos participantes.
- Se **inicia** solo si la publicación está Disponible, no es propia y el perfil está completo. Si ya existe, se abre.
- Se puede **escribir** mientras la publicación exista y no esté Vendida.
- Mensaje de 1 a 500 caracteres, con la lista de caracteres permitidos de la descripción.
- Máximo 20 mensajes por minuto por estudiante.
- Los mensajes no se editan ni se borran.
- El chat nunca muestra el correo ni el teléfono: solo el nombre a mostrar y la foto de perfil.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Contactar | `casos_de_uso_chat_test` (IniciarConversacion), `conversacion_test` (datos del vendedor), `chat_cubit_test` (abrir), CP-53 (POST `rpc/iniciar_conversacion` → 200 con el id) |
| 2. Contactar de nuevo | `chat_cubit_test` (abre con historial), SQL 2 y 43 |
| 3. Tiempo real | `chat_cubit_test` (un mensaje que llega por el `Stream` aparece sin recargar; no se duplica el propio), `bandeja_cubit_test` (sube al primer lugar), CP-57 (POST `/rest/v1/mensajes` → 201 y llegada por el tiempo real), `modelos_chat_test` (lee el registro de Realtime) |
| 4. Publicación propia | `detalle_publicacion_cubit_test` (ya existe), SQL 3 |
| 5. Reservada o Vendida | `detalle_publicacion_cubit_test` (ya existe), CP-54 (400 `publicacion_no_disponible`) |
| 6. Perfil incompleto | `casos_de_uso_chat_test`, CP-54 (400 `perfil_incompleto`) |
| 7. Bandeja | `casos_de_uso_chat_test`, `bandeja_cubit_test`, `modelos_chat_test`, CP-55 (POST `rpc/mis_conversaciones` → 200) |
| 8. No leídos | `bandeja_cubit_test` (incluye `NoLeidosCubit`), `chat_cubit_test` (marca como leída al abrir y al recibir), CP-59 (`rpc/marcar_conversacion_leida`), CP-60 (`rpc/total_no_leidos`) |
| 9. Historial | `casos_de_uso_chat_test`, `chat_cubit_test` (cargar anteriores), CP-56 (segunda página con cursor) |
| 10. Mensaje inválido | `mensaje_validator_test`, `casos_de_uso_chat_test` (no llama al servidor), CP-58 (400 `mensaje_caracteres` → mensaje del campo) |
| 11. Conversación cerrada | `chat_cubit_test` (sin campo de texto), CP-61 (400 `conversacion_cerrada`) |
| 12. Conversación ajena | CP-62 (403 de RLS → sin permiso); SQL 18 a 24 |
| 13. Demasiados mensajes | `chat_cubit_test` (conserva el texto), CP-61 (400 `demasiados_mensajes`) |
| 14. Sin conexión | todos los casos de uso, los dos Cubits, CP-63 (ninguna petición) |
| 15. Error del servidor | los dos Cubits, CP-64 (500 → mensaje genérico, sin IP ni nombres internos; sin sesión → ninguna petición) |

**Pruebas de la base de datos:** la migración se probó en un Postgres 16 local con el stub de Auth, Storage y Realtime: **50 casos, todos pasan**. Entre ellos: un tercer estudiante no ve la conversación ni sus mensajes, no puede escribir en ella ni marcarla como leída; nadie puede enviar a nombre del otro ni editar o borrar mensajes; y siguen funcionando Mis publicaciones, el Feed y la búsqueda.

**Prueba del tiempo real:** el WebSocket de Supabase no se puede simular en el CI. La suscripción queda detrás de una interfaz, y las pruebas de los Cubits le inyectan los mensajes con un `StreamController`. La entrega real entre dos celulares la valida Jesus (Escenario 3).

## 6. Definición de Hecho (Definition of Done) del Sprint 7

- [ ] Las 6 decisiones de la sección 3 confirmadas por los Product Owners; issue #2 actualizado con estos criterios.
- [ ] Código en `feature/HU-07-chat`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261106120000_hu07_chat.sql` aplicada en Supabase **el mismo día** y comprobada con la consulta del final del archivo (4 filas con "sí").
- [ ] Ya no aparece "En desarrollo" al presionar "Contactar al vendedor".
- [ ] Los 15 escenarios Gherkin de la sección 5 pasan manualmente con dos cuentas (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 a HU-06.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info").
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, **al menos 1 aprobación registrada** y CI en estado PASSED antes del merge. El PR menciona el issue #2 (`Closes #2`).
- [ ] Guía de diseño (`docs/Sprint7_Guia_Diseno.md`) entregada a Oziel.
- [ ] Demo en la Sprint Review: dos cuentas (dos celulares, o celular y Chrome) → Detalle → "Contactar al vendedor" → mensaje que llega al otro sin refrescar → globo de no leídos en el Feed → bandeja → responder → marcar la publicación como Vendida → la conversación queda solo para leer → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Sprint de un día:** el trabajo empezó el viernes 6, el mismo día de la Review. Mitigación: la base de datos ya está probada y la lógica se entrega hoy. Si el historial por páginas o el globo del Feed no alcanzan, se entrega lo demás (contactar, enviar, recibir en tiempo real y bandeja) y lo que falte pasa al Sprint 8, avisándolo en la Review.
- **Realtime desactivado en el proyecto:** si el tiempo real no está encendido en Supabase, los mensajes solo aparecen al volver a abrir el chat. Mitigación: la migración agrega `mensajes` a la publicación de Realtime; José Luis lo comprueba con la consulta del final del archivo (fila "mensajes en tiempo real"). Si el WebSocket se cae, el chat vuelve a cargar los mensajes al reconectarse.
- **Probar con una sola cuenta:** el tiempo real necesita dos cuentas. Mitigación: Jesus usa dos celulares, o un celular y Chrome con otra cuenta.
- **Datos personales:** alguien podría escribir su teléfono en un mensaje. Mitigación: la app nunca muestra el correo ni el teléfono; los participantes deciden qué compartir.
- **Spam:** límite de 20 mensajes por minuto en la base de datos.
- **Fusiones sin aprobación:** los PR #30 a #34 se fusionaron sin aprobación registrada y `develop` sigue sin protección. Mitigación: configurarla antes de abrir el PR de HU-07.

## 8. Seguridad

HU-07 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **Mínimo privilegio:** solo los dos participantes leen la conversación y sus mensajes (RLS). Las conversaciones solo se crean con `iniciar_conversacion`, que revisa todas las reglas con el estudiante de la sesión. Nadie puede editar ni borrar mensajes ni cambiar conversaciones. El rol `anon` no tiene acceso.
- **No confiar en el cliente:** el autor del mensaje sale de la sesión; si la app manda otro, la base lo rechaza. La base revisa el estado de la publicación en cada mensaje.
- **Tiempo real con las mismas reglas:** Supabase Realtime respeta RLS, así que cada estudiante solo recibe por WebSocket los mensajes de sus conversaciones. La conexión va cifrada (WSS/TLS).
- **Validación de entrada:** la lista de caracteres permitidos del Sprint 6 también aplica a los mensajes, en la app y en la base.
- **Disponibilidad:** máximo 20 mensajes por minuto, 30 mensajes por página y 100 conversaciones por petición.
- **Privacidad:** el chat solo muestra el nombre a mostrar y la foto de perfil; nunca el correo.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones).

## 9. Pendientes arrastrados del Sprint 6

Estado revisado en GitHub el viernes 6 de noviembre:

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Configurar la protección de `develop` (hoy **no tiene protección**; los PR #32, #33 y #34 se fusionaron sin aprobación) | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Configuración del repo | Pendiente |
| Aprobar y fusionar el PR #29 `develop` → `main` (abierto desde el 9 de octubre; último merge a `main`: PR #22) | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |
| Ordenar los issues: cerrar #4, #5 y #6 (HU-03, HU-05 y HU-01, ya terminadas), actualizar el #2 y crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | GitHub Issues | Pendiente |
| Confirmar que la migración de caracteres permitidos (`20261030120000_validacion_caracteres.sql`) está aplicada en Supabase | Orduña Garrido Jose Luis | Consulta del final del archivo | Por confirmar |
| Validación manual de HU-06 (Mis publicaciones, Gestionar y Editar) y de los caracteres permitidos | Torres Valeriano Jesus | Checklist con capturas | Pendiente |
| Diseño en Figma de las pantallas de HU-05 y HU-06 | Diaz Huerta Diego Oziel | Rama de diseño desde `develop` | Pendiente |
| Cargar publicaciones de prueba de varias carreras | Cadena Vega Jonathan | Datos de prueba en Supabase | Pendiente |
| Confirmar con Servicios Escolares el acomodo carrera → división | Oziel y Jesus | Si cambia algo, Jonathan prepara una migración | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | Falta la carpeta `ios/` | Pendiente |

**Orden sugerido de fusión a `develop`:** `feature/HU-07-chat` → ajustes de diseño de Oziel. Después de la Review: `develop` → `main`.
