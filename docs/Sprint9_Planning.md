# Planeación del Sprint 9 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 9 |
| **Duración** | 1 semana (lunes 16 a viernes 20 de noviembre de 2026; el lunes 16 fue día de descanso obligatorio por el aniversario de la Revolución) |
| **Inicio real del trabajo** | Jueves 19 de noviembre de 2026 (planeación, migración y pruebas de la base). Del martes 17 al miércoles 18 no hubo cambios en el repositorio (el último cambio en `develop` es la fusión del PR #36 del viernes 13) |
| **Fecha de cierre (Sprint Review)** | Viernes 20 de noviembre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-09-reputacion` |
| **Issue de GitHub** | **#38** (todavía no existe: hay que crearlo con el texto del anexo A **antes** que cualquier otro issue o PR, para que GitHub le dé el número 38) |

> **Aviso:** el Sprint 9 tiene 4 días hábiles en el calendario, pero el trabajo empezó el jueves 19: en la práctica son **2 días**. Ver riesgos (sección 7).

## 2. Sprint Goal

Cuando un estudiante marca su publicación como **Vendida**, elige **con quién hizo el trato** entre las personas que le escribieron por esa publicación. Después, **los dos se califican** una sola vez, de **1 a 5 estrellas** y con un comentario opcional, dentro de los 14 días siguientes. La **reputación** de cada estudiante se ve en **Mi perfil**, en el **Detalle de la publicación** y en el **encabezado del chat**. Nadie puede calificarse a sí mismo, calificar dos veces, calificar tratos ajenos ni ver o cambiar calificaciones de otros, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-09** (PB-09, issue #38) | Reputación de 1 a 5 estrellas | Media (Should Have) · **por confirmar** | 5 pts · **por confirmar** |

> **Ojo:** la prioridad y los puntos de HU-09 **no aparecen** en el repositorio ni en los documentos del proyecto que se revisaron (las planeaciones de los Sprints 1 a 8 solo traen su propia historia). Se proponen **Media (Should Have)** porque sostiene el KPI 3 del issue #8 (calificación promedio mayor a 4.2/5), y **5 pts** porque reutiliza el chat (HU-07) y los estados (HU-06). Los Product Owners los confirman contra la planeación general.

> **Como** estudiante que compró o vendió un artículo, **quiero** calificar a la otra persona con 1 a 5 estrellas y un comentario breve, **para** construir confianza dentro de la comunidad de UTrueque.

**Decisiones que deben confirmar los Product Owners (Oziel y Jesus) el viernes 20, antes de la Review:**

| # | Pregunta | Recomendación del equipo de desarrollo | Por qué |
| :--- | :--- | :--- | :--- |
| 1 | ¿Quién puede **calificar**? | Solo el **vendedor** y el **comprador** de una publicación **Vendida** que tuvieron conversación. Cada uno califica **al otro**. | Así solo califica quien de verdad hizo el trato. |
| 2 | ¿Cómo se sabe **quién compró**? | Al **marcar como Vendido**, el vendedor elige a la persona entre las conversaciones de **esa publicación** en las que el interesado **escribió al menos un mensaje**. También puede elegir **"Lo vendí fuera de UTrueque"**: entonces nadie califica. | Reutiliza el chat de HU-07. Pedir que el interesado haya escrito evita elegir a alguien que solo abrió el chat. |
| 3 | ¿Cuántas calificaciones? ¿Se **editan** o **borran**? | **Una por persona y por trato.** **No** se editan ni se borran. | Igual que los mensajes de HU-07: evita cambiar una calificación como venganza o por presión. |
| 4 | ¿El **comentario** es obligatorio? ¿Cuántos caracteres? | **Opcional**, de hasta **200 caracteres**, con la **lista de caracteres permitidos del Sprint 6** (la de la descripción: sin emojis ni `< > { } ; ' "`). | Las estrellas bastan para la reputación. 200 caracteres alcanzan para una opinión breve. |
| 5 | ¿Dónde se ve la **reputación**? | En **Mi perfil** (promedio, total, cuántas de cada estrella y las calificaciones recibidas), en el **Detalle de la publicación** (junto al nombre del vendedor) y en el **encabezado del chat** (del otro estudiante). | Son los momentos en que se decide si confiar en alguien. El perfil público de otro estudiante queda para el backlog. |
| 6 | ¿Cuánto **tiempo** hay para calificar? | **14 días** después de la venta. | Es el mismo plazo del KPI 2 (vender en menos de 14 días) y del punto de encuentro (HU-08). |
| 7 | ¿Qué se muestra a quien **no tiene calificaciones**? | **"Nuevo en UTrueque · Sin calificaciones aún"**, sin estrellas ni "0.0". | Un 0.0 haría parecer que lo calificaron mal. |
| 8 | ¿Qué **número** se muestra con pocas calificaciones? | Con **menos de 5** calificaciones, el **promedio ajustado** (ver patrón de diseño), y siempre junto con el total: "4.3 · 2 calificaciones". Con **5 o más**, el **promedio real**. | Con una sola calificación de 5 nadie debería quedar arriba de alguien con 30 calificaciones de 4.8. |

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Notificación push de "Califica tu trato" y recordatorios → **Sprint 10 (HU-10)**.
- Perfil público de otro estudiante con sus publicaciones y comentarios, reportar una calificación injusta y que las calificaciones se vean hasta que los dos califiquen → backlog.
- Ordenar o filtrar el Feed por reputación → backlog.
- Calificar ventas que se marcaron como Vendidas **antes** de este sprint (no tienen comprador registrado).

**Patrón de diseño: Strategy.** La reputación se puede calcular de dos maneras:

| Estrategia | Cómo calcula | Ejemplo |
| :--- | :--- | :--- |
| `PromedioSimple` | Suma de estrellas entre el total. | 5 y 4 → **4.5** |
| `PromedioAjustado` | Suma **3 calificaciones imaginarias de 4 estrellas** antes de promediar: (estrellas + 3 × 4) ÷ (total + 3). | Una sola de 5 → (5 + 12) ÷ 4 = **4.3**. Una sola de 1 → (1 + 12) ÷ 4 = **3.3** |

Las dos cumplen el mismo contrato `EstrategiaReputacion.calcular(resumen)`. Un **selector** (`ElegirEstrategiaReputacion`) usa la ajustada con menos de 5 calificaciones y la simple con 5 o más. La pantalla y el Cubit solo piden "calcula la reputación", sin saber cuál se usó. **Por qué encaja:** la regla de cómo mostrar la reputación es justo lo que los Product Owners pueden querer cambiar (decisión 8); con Strategy se cambia la estrategia o el umbral **en un solo lugar**, sin tocar la base, las pantallas ni las pruebas de las demás. La base de datos **no calcula el promedio**: solo regresa **cuántas calificaciones hay de cada estrella**, así que nunca se expone quién calificó qué.

Se eligió HU-09 porque, con el chat (HU-07) y el punto de encuentro (HU-08) listos, el último paso de un trato es **dejar constancia de cómo salió**, y es lo que mide el KPI 3 del issue #8.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Confirmar la prioridad, los puntos y las 8 decisiones de la sección 3, y validar los criterios Gherkin de HU-09 | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Crear el issue #38 "HU-09: Reputación de 1 a 5 estrellas" con el texto del anexo A (**primero**, para que quede con el número 38) | Diaz Huerta Diego Oziel | Product Owner |
| Pendientes de issues del Sprint 8: cerrar a mano el #3 (PR #36) y el #2 (PR #35), cerrar #4, #5 y #6, ordenar #7 y #8 y crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: tablas `ventas` y `calificaciones`, reglas RLS y funciones (`compradores_posibles`, `marcar_vendida`, `calificar`, `tratos_por_calificar`, `reputacion_usuario`, `calificaciones_recibidas`) | Cadena Vega Jonathan | Develop Team |
| Lógica: entidades, estrategias de reputación (patrón Strategy), validador de calificación, casos de uso, modelos y repositorio | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de dominio y datos, y casos AAA del API REST simulado (CP-77 a CP-88) | Cadena Vega Jonathan | Develop Team |
| Estado: `ElegirCompradorCubit` (hoja "¿A quién se lo vendiste?"), venta con comprador en `GestionarPublicacionCubit`, `CalificarCubit` (formulario), `ReputacionCubit` (resumen de un estudiante), `TratosPorCalificarCubit` y `CalificacionesRecibidasCubit` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas: hoja "¿A quién se lo vendiste?" al marcar Vendido, hoja "Calificar", banner "Califica tu trato" en el chat y en Mi perfil, reputación en Mi perfil, Detalle y encabezado del chat, con Keys (`ReputacionKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de los Cubits (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño en Figma de la hoja Calificar, las estrellas y la reputación (guía `docs/Sprint9_Guia_Diseno.md`), y lo pendiente del chat, el mapa y las tarjetas del punto de encuentro | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar el Pull Request hacia `develop` (mínimo 1 aprobación registrada, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente HU-09 **con dos cuentas** (vender, calificar los dos, ver la reputación) | Torres Valeriano Jesus | Product Owner / Validación |
| Aplicar en Supabase la migración de HU-09 **el mismo día** y comprobarla con la consulta del final del archivo (8 filas con "sí"); correr también la consulta del KPI | Orduña Garrido Jose Luis | Scrum Master |
| Configurar la protección de `develop` para que exija 1 aprobación (lo hace Luis Angel, que es el dueño del repositorio) | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Scrum Master / Develop Team |
| Aprobar y fusionar el PR #29 `develop` → `main` | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 9, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-09

```gherkin
Historia: HU-09 Reputación de 1 a 5 estrellas (issue #38)
Como estudiante que compró o vendió un artículo
Quiero calificar a la otra persona con 1 a 5 estrellas y un comentario breve
Para construir confianza dentro de la comunidad de UTrueque

  Escenario 1: Marcar como Vendido eligiendo al comprador
    Dado que el vendedor tiene una publicación Disponible o Reservada
    Y dos estudiantes le escribieron por esa publicación
    Cuando elige "Marcar como Vendido"
    Entonces aparece la hoja "¿A quién se lo vendiste?" con esos dos estudiantes
    Y la opción "Lo vendí fuera de UTrueque"
    Cuando elige a uno y confirma
    Entonces la publicación cambia a "Vendido"
    Y se muestra "Listo. Ya pueden calificarse."

  Escenario 2: Vendido fuera de UTrueque
    Dado que el vendedor elige "Lo vendí fuera de UTrueque"
    Cuando confirma
    Entonces la publicación cambia a "Vendido"
    Y nadie puede calificar ese trato

  Escenario 3: El comprador califica al vendedor
    Dado que el comprador tiene un trato de hace menos de 14 días sin calificar
    Cuando abre el chat de esa publicación o "Mi perfil"
    Entonces ve el aviso "Califica tu trato con <vendedor>"
    Cuando toca "Calificar", elige 5 estrellas, escribe "Muy puntual" y presiona "Enviar calificación"
    Entonces se muestra "¡Gracias! Tu calificación ayuda a la comunidad."
    Y el aviso desaparece

  Escenario 4: El vendedor califica al comprador
    Dado que el vendedor tiene el mismo trato sin calificar
    Cuando califica al comprador con 4 estrellas sin comentario
    Entonces la calificación se guarda
    Y la reputación del comprador incluye esas 4 estrellas

  Escenario 5: Ver mi reputación
    Dado que el estudiante recibió calificaciones
    Cuando entra a "Mi perfil"
    Entonces ve su promedio con una decimal, el total, cuántas tiene de cada estrella
    Y la lista de calificaciones recibidas (estrellas, comentario, quién y de qué publicación), de la más nueva a la más vieja

  Escenario 6: Ver la reputación del otro
    Dado que un estudiante abre el Detalle de una publicación o un chat
    Entonces junto al nombre del vendedor (o del otro estudiante) ve sus estrellas, el promedio y el total
    Pero no ve los comentarios ni quién lo calificó

  Escenario 7: Sin calificaciones
    Dado que un estudiante todavía no tiene calificaciones
    Entonces se muestra "Nuevo en UTrueque · Sin calificaciones aún"
    Y no se muestran estrellas ni "0.0"

  Escenario 8: Pocas calificaciones (promedio ajustado)
    Dado que un estudiante tiene una sola calificación de 5 estrellas
    Entonces se muestra "4.3 · 1 calificación"
    Y cuando llega a 5 calificaciones se muestra su promedio real

  Escenario 9: Calificar dos veces
    Dado que el estudiante ya calificó un trato
    Entonces ya no ve el aviso ni el botón "Calificar" de ese trato
    Y si lo intenta saltándose la app, el servidor lo rechaza
    Y se muestra "Ya calificaste este trato."

  Escenario 10: Plazo vencido
    Dado que pasaron más de 14 días desde la venta
    Entonces el trato ya no aparece para calificar
    Y si alguien lo intenta saltándose la app, se muestra "Ya pasaron los 14 días para calificar este trato."

  Escenario 11: Calificaciones no permitidas
    Dado que un estudiante intenta, saltándose la app, calificarse a sí mismo, calificar un trato ajeno,
      elegir a un comprador que no le escribió, o editar, borrar o leer una por una las calificaciones de otros
    Entonces el servidor rechaza la acción y no muestra nada ajeno

  Escenario 12: Comentario no válido
    Dado que el estudiante escribe un comentario de más de 200 caracteres o con caracteres no permitidos
    Entonces el campo muestra el error y "Enviar calificación" no se habilita
    Y si alguien lo envía saltándose la app, el servidor lo rechaza

  Escenario 13: Sin conexión
    Dado que el dispositivo no tiene conexión a internet
    Cuando el estudiante intenta marcar como Vendido o calificar
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y la pantalla conserva las estrellas y el comentario que eligió

  Escenario 14: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante califica o se carga la reputación
    Entonces se muestra "No pudimos completar la acción. Inténtalo de nuevo."
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- Solo el dueño marca su publicación como Vendida, desde Disponible o Reservada (patrón State de HU-06; Vendido es final).
- El comprador se elige entre las conversaciones de esa publicación en las que el interesado escribió al menos un mensaje, o "fuera de UTrueque" (sin calificaciones).
- Cada participante califica **al otro**, una sola vez por trato, de 1 a 5 estrellas enteras.
- Comentario opcional de hasta 200 caracteres, con la lista de caracteres permitidos del Sprint 6.
- Hay 14 días después de la venta para calificar. Las calificaciones no se editan ni se borran.
- Cada estudiante ve el detalle de las calificaciones que dio y recibió; de los demás, solo el resumen por estrellas.
- Promedio: ajustado con menos de 5 calificaciones, real con 5 o más (patrón Strategy).

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Vender eligiendo comprador | `casos_de_uso_reputacion_test` (MarcarVendida), `vender_con_comprador_test`, `reputacion_cubits_test` (ElegirCompradorCubit), CP-77 (POST `rpc/compradores_posibles`), CP-78 (POST `rpc/marcar_vendida` → 200 con el id); SQL 1, 8, 9, 11 y 12 |
| 2. Fuera de UTrueque | `vender_con_comprador_test`, CP-78 (id `null`); SQL 13 y 14 |
| 3. Comprador califica | `calificacion_validator_test`, `calificar_cubit_test`, CP-80 (POST `rpc/tratos_por_calificar`), CP-81 (POST `rpc/calificar`); SQL 17, 27, 28 y 30 |
| 4. Vendedor califica | `calificar_cubit_test`, CP-81; SQL 35 y 36 |
| 5. Mi reputación | `estrategias_reputacion_test`, `reputacion_cubits_test` (CalificacionesRecibidasCubit), CP-83 (POST `rpc/calificaciones_recibidas`); SQL 37, 56 a 58 |
| 6. Reputación del otro | `reputacion_cubits_test` (ReputacionCubit), `modelos_reputacion_test`, CP-82 (POST `rpc/reputacion_usuario`); SQL 40 a 42 |
| 7. Sin calificaciones | `estrategias_reputacion_test` (sin calificaciones → nada), `reputacion_cubits_test`; SQL 43 |
| 8. Pocas calificaciones | `estrategias_reputacion_test` (ajustado, simple y selector) |
| 9. Dos veces | `calificar_cubit_test`, `reputacion_cubits_test` (TratosPorCalificarCubit), CP-84 (400 `calificacion_duplicada`); SQL 29 |
| 10. Plazo vencido | `calificacion_validator_test` (TratoPorCalificar), `calificar_cubit_test`, CP-85 (400 `plazo_vencido`); SQL 47 y 48 |
| 11. No permitidas | CP-86 (42501 → sin permiso), CP-79 (400 `comprador_no_valido`); SQL 2 a 7, 10, 16, 31 a 34, 38 a 41, 45, 46 y 49 a 55 |
| 12. Comentario | `calificacion_validator_test`, `calificar_cubit_test`, CP-87 (400 `comentario_caracteres` / `comentario_largo`); SQL 20 a 26 |
| 13. Sin conexión | todos los casos de uso, los Cubits, CP-88 (ninguna petición) |
| 14. Error del servidor | los Cubits, CP-88 (500 → mensaje genérico) |

**Pruebas de la base de datos:** la migración se probó el jueves 19 en un Postgres 16 local con el stub de Auth, Storage y Realtime, encima de las 9 migraciones anteriores, y corrida **dos veces** (es idempotente): **60 casos, todos pasan**. Entre ellos, un estudiante **no puede calificarse a sí mismo**, **no puede calificar dos veces** el mismo trato, **no puede calificar tratos ajenos**, y **no puede ver una por una, editar ni borrar** calificaciones de otros (solo su resumen por estrellas). También se comprobó que el chat (HU-07) y el punto de encuentro (HU-08) se cierran al vender, y que el "Marcar como Vendido" de HU-06 de los APK viejos sigue funcionando.

## 6. Definición de Hecho (Definition of Done) del Sprint 9

- [ ] Prioridad, puntos y las 8 decisiones de la sección 3 confirmadas por los Product Owners; issue #38 creado con estos criterios.
- [ ] Código en `feature/HU-09-reputacion`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261119120000_hu09_reputacion.sql` aplicada en Supabase **el mismo día** y comprobada con la consulta del final del archivo (8 filas con "sí").
- [ ] Los 14 escenarios Gherkin de la sección 5 pasan manualmente con dos cuentas (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 a HU-08.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info"), con Flutter 3.47.9 (la versión fija del CI).
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, **al menos 1 aprobación registrada** y CI en estado PASSED antes del merge. El PR dice `Closes #38`.
- [ ] Anexo de CP-77 a CP-88 en `docs/Plan_de_Pruebas.md`.
- [ ] Guía de diseño (`docs/Sprint9_Guia_Diseno.md`) entregada a Oziel.
- [ ] Demo en la Sprint Review: dos cuentas con chat → el vendedor marca Vendido y elige al comprador → el comprador ve "Califica tu trato" y pone 5 estrellas con comentario → el vendedor califica al comprador → la reputación aparece en Mi perfil, el Detalle y el chat → intentar calificar otra vez (no aparece) → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Sprint de dos días:** el trabajo empezó el jueves 19 y la Review es el viernes 20. Mitigación: la base de datos ya está probada el jueves. Si no alcanza, se entrega lo esencial (elegir comprador, calificar y ver la reputación en Mi perfil) y la reputación en el Detalle y el chat pasa al Sprint 10, avisándolo en la Review.
- **Decisiones sin confirmar:** si los Product Owners cambian el plazo (14 días) o el tamaño del comentario, solo cambia un número en la migración y en el validador. Si cambian la decisión 8, solo cambia el selector de estrategia.
- **Calificaciones infladas entre amigos:** dos amigos podrían "venderse" algo para calificarse con 5. Mitigación: el comprador debe haber escrito en el chat y solo hay una calificación por publicación vendida. Detectarlo mejor (reportar, límites) queda en el backlog.
- **Ventas viejas sin comprador:** las publicaciones vendidas antes de este sprint no tienen comprador registrado y no se pueden calificar. Mitigación: se avisa en la Review; para la demo se crea una venta nueva.
- **APK viejos:** el "Marcar como Vendido" de HU-06 sigue funcionando, pero esas ventas no se califican. Mitigación: instalar el APK nuevo para la demo y la validación.
- **Migración de HU-08 sin confirmar:** HU-09 necesita las de HU-07 y HU-08. Mitigación: José Luis corre primero la consulta de comprobación de HU-08 (7 filas con "sí"); la de HU-09 también lo revisa.
- **Fusiones sin aprobación:** los PR #35 y #36 se fusionaron sin aprobación y `develop` sigue sin protección. Mitigación: Luis Angel la configura antes de abrir el PR de HU-09.

## 8. Seguridad

HU-09 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **Mínimo privilegio:** las ventas solo las ven sus dos participantes y las calificaciones solo quien la dio y quien la recibió (RLS). Nadie puede escribir directo en `ventas` ni en `calificaciones`: solo con `marcar_vendida` y `calificar`, que revisan todas las reglas con el estudiante de la sesión. El rol `anon` no tiene acceso.
- **No confiar en el cliente:** quién califica sale de la sesión y **a quién** se califica sale de la venta, no de un parámetro; así nadie se califica a sí mismo ni a un tercero. El comprador debe ser alguien que escribió por esa publicación. Las estrellas, el comentario y el plazo los revisa la base.
- **Minimización:** de los demás solo se ve cuántas calificaciones tienen de cada estrella, nunca quién calificó ni el comentario. Los comentarios usan la lista de caracteres permitidos del Sprint 6 (sin `< > { } ; ' "` ni emojis).
- **Integridad:** una calificación por persona y por trato, sin editar ni borrar. Si alguien borra su cuenta, se borran sus tratos y calificaciones.
- **Errores sin detalles internos:** cada rechazo trae una pista fija y la app muestra un mensaje claro.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones).

## 9. Pendientes arrastrados del Sprint 8

Estado revisado en GitHub el jueves 19 de noviembre:

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| El PR #36 (punto de encuentro) se fusionó el viernes 13 **sin aprobación registrada** y sin `Closes #3`: el issue #3 sigue abierto | Diaz Huerta Diego Oziel | Cerrar el #3 a mano con un comentario que mencione el PR #36 | Pendiente |
| El issue #2 (HU-07, chat) sigue abierto aunque lo terminó el PR #35 | Diaz Huerta Diego Oziel | Cerrar el #2 a mano con un comentario que mencione el PR #35 | Pendiente |
| Ordenar los issues: cerrar #4, #5 y #6 (historias ya terminadas), revisar #7 (repositorio y CI) y #8 (caso de estudio, del que sale el KPI de reputación) y crear el issue "HU-04: Feed de Publicaciones" (**después** del #38) | Diaz Huerta Diego Oziel | GitHub Issues | Pendiente |
| Configurar la protección de `develop` (hoy **no tiene protección**) | Gonzalez Casarrubias Luis Angel (dueño) y Orduña Garrido Jose Luis | Settings → Branches → regla para `develop` con 1 aprobación | Pendiente |
| Aprobar y fusionar el PR #29 `develop` → `main` (abierto desde el 9 de octubre, hoy con 77 commits; GitHub lo marca **bloqueado**: le falta la aprobación que pide `main`). El PR #37 (rama de HU-08 → `main`) se abrió por error el viernes 13 y se cerró sin fusionar | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |
| Adaptar el código a Flutter 3.50 (marca `package:flutter/material.dart` como obsoleto) para quitar la versión fija 3.47.9 del CI | Cadena Vega Jonathan y Gonzalez Casarrubias Luis Angel | Rama `chore/flutter-3-50` desde `develop`, después de HU-09 | Pendiente |
| Diseño en Figma del chat, el mapa y las tarjetas del punto de encuentro | Diaz Huerta Diego Oziel | Rama de diseño desde `develop` | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | Sigue sin existir la carpeta `app/ios/` | Pendiente |
| Confirmar que la migración de HU-08 (`20261111120000_hu08_punto_encuentro.sql`) está aplicada y validar el punto de encuentro con dos cuentas | Orduña Garrido Jose Luis y Torres Valeriano Jesus | Consulta del final del archivo y checklist | Por confirmar |

**Orden sugerido de fusión a `develop`:** `feature/HU-09-reputacion` → ajustes de diseño de Oziel → `chore/flutter-3-50`. Después de la Review: `develop` → `main`.

## Anexo A. Texto para crear el issue #38

**Título:** `HU-09: Reputación de 1 a 5 estrellas`

**Etiquetas sugeridas:** `user story`, `Sprint 9`

**Cuerpo:**

```markdown
## Historia de usuario
**Como** estudiante que compró o vendió un artículo,
**quiero** calificar a la otra persona con 1 a 5 estrellas y un comentario breve,
**para** construir confianza dentro de la comunidad de UTrueque.

**Prioridad:** Media (Should Have) · **Estimación:** 5 pts (por confirmar)
**Patrón de diseño:** Strategy (promedio simple / promedio ajustado con pocas calificaciones)
**KPI relacionado:** #8 — calificación promedio de reputación mayor a 4.2/5

## Criterios de aceptación
Escenario 1: Marcar como Vendido eligiendo al comprador
  Dado que el vendedor tiene una publicación Disponible o Reservada y dos estudiantes le escribieron
  Cuando elige "Marcar como Vendido"
  Entonces elige a quién se lo vendió (o "Lo vendí fuera de UTrueque") y la publicación cambia a "Vendido"

Escenario 2: Calificar el trato
  Dado que el comprador y el vendedor tienen un trato de hace menos de 14 días
  Cuando cada uno elige de 1 a 5 estrellas y, si quiere, escribe un comentario de hasta 200 caracteres
  Entonces la calificación se guarda y se suma a la reputación del otro

Escenario 3: Ver la reputación
  Dado que un estudiante abre Mi perfil, el Detalle de una publicación o un chat
  Entonces ve el promedio y el total de calificaciones (o "Nuevo en UTrueque · Sin calificaciones aún")

Escenario 4: Calificaciones no permitidas
  Dado que alguien intenta calificarse a sí mismo, calificar dos veces, calificar un trato ajeno o pasados 14 días
  Entonces el sistema lo rechaza

## Reglas de negocio
- Solo califican el vendedor y el comprador elegido; cada uno al otro, una vez por trato.
- Las calificaciones no se editan ni se borran.
- Comentario opcional con la lista de caracteres permitidos del Sprint 6.

Detalle completo: docs/Sprint9_Planning.md
```
