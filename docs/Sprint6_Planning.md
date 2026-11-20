# Planeación del Sprint 6 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 6 |
| **Duración** | 1 semana (lunes 26 a viernes 30 de octubre de 2026) |
| **Inicio real del trabajo** | Jueves 29 de octubre de 2026 (planeación y migración). Entre el lunes 26 y el miércoles 28 no hubo cambios en el repositorio |
| **Fecha de cierre (Sprint Review)** | Viernes 30 de octubre de 2026 |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-06-mis-publicaciones` |
| **Issue de GitHub** | #1 (aparece como "HU-04: Gestión de 'Mis Publicaciones' y Control de Estados"; en los documentos y el tablero es **HU-06**). Hoy está **cerrado** aunque la historia no se ha hecho: hay que reabrirlo |

## 2. Sprint Goal

Un estudiante con sesión iniciada **administra sus propias publicaciones** desde "Mi perfil": ve sus publicaciones **activas** (Disponibles y Reservadas) y su **historial de finalizadas** (Vendidas); puede **marcarlas como Reservado, regresarlas a Disponible o marcarlas como Vendido** (con confirmación, porque es final), **editarlas y borrarlas mientras están Disponibles**. El Feed y el Detalle muestran el cambio al momento, nadie puede modificar publicaciones ajenas, y todo queda fusionado a `develop` con el pipeline de CI en verde.

## 3. Historia seleccionada del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-06** (PB-06, issue #1) | Gestión de "Mis publicaciones" y control de estados | Media (Should Have) | 8 pts |

> **Como** estudiante ofertante, **quiero** editar o marcar mis publicaciones como "Reservado" o "Vendido/Entregado", **para** mantener mi catálogo actualizado y evitar que me contacten por artículos no disponibles.

**Decisiones que deben confirmar los Product Owners (Oziel y Jesus) el jueves 29:**

| # | Pregunta | Recomendación del equipo de desarrollo | Por qué |
| :--- | :--- | :--- | :--- |
| 1 | ¿Se agrega el estado **"Pausado / Desactivado"** que menciona el issue #1? | **No en este sprint.** Queda en el backlog. | El sprint tiene 2 días. Un cuarto estado obliga a cambiar la base, el Feed, la búsqueda, el dominio y las pruebas, y los APK ya instalados no conocen ese estado (fallarían al abrir el detalle de una publicación pausada). Hoy "Reservado" ya evita que lo contacten y "Borrar" sirve si ya no quiere ofrecerlo. |
| 2 | ¿Qué se puede **editar** y cuándo? | Título, descripción, categoría, modalidad, precio y fotos, **solo si está Disponible**. Reservada: primero se libera. Vendida: solo se ve. | Si hay un trato en curso, cambiar el precio o las fotos sería injusto para el comprador. La base de datos aplica la misma regla. |
| 3 | ¿Se permite **borrar**? | **Sí, solo si está Disponible**, con confirmación. Se borran también sus fotos. | Una Reservada tiene un trato en curso y una Vendida queda en el historial (la reputación de HU-09 la usará). |
| 4 | ¿"Marcar como Vendido" pide confirmación? | **Sí**, con el aviso "Ya no podrás cambiar su estado ni editarla". Se puede vender directo desde Disponible (entrega inmediata) o desde Reservado. | Vendido es el estado final del patrón State. |
| 5 | ¿Qué es el "historial de finalizadas"? | La pestaña **Finalizadas** de "Mis publicaciones", con las Vendidas, de la más nueva a la más vieja. | Es lo que pide el Escenario 2 del issue #1. |

**Fuera del alcance (para que no se cuele trabajo de otros sprints):**

- Estado "Pausado / Desactivado" → backlog (si los PO lo confirman, se propone para un sprint posterior).
- Ver las publicaciones de otro estudiante en su perfil público.
- Elegir a quién se le vendió o se le reservó (necesita el chat) → **Sprint 7 (HU-07)** o **HU-09** (reputación).
- Avisar a los interesados cuando una publicación se reserva o se vende → **Sprint 10 (notificaciones)**.
- Contactar al vendedor sigue abriendo "En desarrollo" → **Sprint 7 (HU-07, chat)**.

**Patrón de diseño:** **State** (el de HU-03). Cada estado decide qué acciones muestra la gestión:

| Estado | Acciones del dueño |
| :--- | :--- |
| Disponible | Marcar como Reservado · Marcar como Vendido · Editar · Borrar |
| Reservado | Volver a Disponible · Marcar como Vendido |
| Vendido | Ninguna (solo se ve en el historial) |

Si se pide una acción que el estado no permite, el estado la rechaza (`TransicionNoPermitidaFailure`) y la base de datos también.

Se eligió HU-06 porque las publicaciones ya se crean, se ven y se buscan (HU-03 a HU-05), pero el dueño no puede marcarlas como reservadas o vendidas: hoy un artículo vendido sigue en el Feed y lo siguen contactando. Además, el chat (HU-07) necesita que "Reservado" ya funcione.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Confirmar las 5 decisiones de la sección 3 y validar los criterios de aceptación (Gherkin) de HU-06 | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Reabrir el issue #1 y actualizarlo con los criterios de la sección 5; actualizar el #5 y crear el issue "HU-04: Feed de Publicaciones" pendiente | Diaz Huerta Diego Oziel | Product Owner |
| Base de datos: función `mis_publicaciones` (Activas o Finalizadas, por páginas), índice por dueño y fecha, y reglas "solo Disponible se edita o se borra" | Cadena Vega Jonathan | Develop Team |
| Lógica: acciones por estado en `EstadoPublicacion` (la página reutiliza `PaginaFeed`), fotos ya guardadas al editar (`FotoArticulo.guardada`), casos de uso `ObtenerMisPublicaciones`, `CambiarEstadoPublicacion`, `EditarPublicacion` y `BorrarPublicacion` (con sus fotos), fallos nuevos, modelo y repositorio contra Supabase | Cadena Vega Jonathan | Develop Team |
| Pruebas unitarias de casos de uso y modelos, y pruebas del API REST simulado con patrón AAA (CP-36 a CP-47) | Cadena Vega Jonathan | Develop Team |
| Estado y navegación: `MisPublicacionesCubit`, `GestionarPublicacionCubit` y `PublicacionCubit` en modo edición (el mismo formulario de "Publicar artículo"); aviso de cambios al Feed (`AvisosPublicaciones`); rutas `/mis-publicaciones` y `/publicacion/editar`; quitar los dos "En desarrollo" del Sprint 6 | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pantallas: "Mis publicaciones" (pestañas Activas y Finalizadas, scroll infinito, jalar para actualizar, vacío, error y sin conexión), hoja "Gestionar publicación" con confirmaciones y "Editar publicación" reutilizando el formulario de "Publicar artículo", con la paleta del logo y Keys (`MisPublicacionesKeys`, `GestionarKeys`) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Pruebas de los tres Cubits (una por escenario Gherkin como mínimo) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Permiso de galería en iPhone (`ios/Runner/Info.plist`), en cuanto exista la carpeta `ios/` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Diseño de "Mis publicaciones" y "Gestionar publicación" en Figma **antes** de programar (acción de mejora del Sprint 5) y ajustes visuales en la rama | Diaz Huerta Diego Oziel | Product Owner / Diseño |
| Revisar y aprobar los Pull Requests hacia `develop` (mínimo 1 aprobación registrada, CI en verde) | Diaz Huerta Diego Oziel | Product Owner |
| Validar manualmente los escenarios de HU-06 y los casos pendientes de HU-01 a HU-05 contra el build | Torres Valeriano Jesus | Product Owner / Validación |
| Confirmar con Servicios Escolares el acomodo carrera → división | Diaz Huerta Diego Oziel y Torres Valeriano Jesus | Product Owner |
| Aplicar en Supabase la migración de HU-06 **el mismo día que se entrega** y comprobarla con la consulta del final del archivo | Orduña Garrido Jose Luis | Scrum Master |
| Configurar la protección de `develop` para que exija 1 aprobación (con Luis Angel, dueño del repo) | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Scrum Master / Develop Team |
| Aprobar y fusionar el PR #29 `develop` → `main` | Orduña Garrido Jose Luis | Scrum Master |
| Configurar el tablero del Sprint 6, dar seguimiento en las Dailies y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |

## 5. Criterios de aceptación (Gherkin) - HU-06

```gherkin
Historia: HU-06 Gestión de "Mis publicaciones" y control de estados (issue #1)
Como estudiante ofertante
Quiero editar o marcar mis publicaciones como "Reservado" o "Vendido/Entregado"
Para mantener mi catálogo actualizado y evitar que me contacten por artículos no disponibles

  Escenario 1: Ver mis publicaciones activas
    Dado que el estudiante inició sesión y tiene publicaciones
    Cuando entra a "Mi perfil" y toca "Mis publicaciones"
    Entonces ve la pestaña "Activas" con sus publicaciones Disponibles y Reservadas,
      de la más nueva a la más vieja
    Y cada tarjeta muestra la portada, el título, el precio o la modalidad y el estado
    Y no aparece ninguna publicación de otro estudiante
    Y al llegar al final se cargan las siguientes 20 sin repetir ninguna

  Escenario 2: Historial de finalizadas
    Dado que el estudiante está en "Mis publicaciones"
    Cuando toca la pestaña "Finalizadas"
    Entonces ve sus publicaciones Vendidas, de la más nueva a la más vieja
    Y no tienen botón de gestionar ni de editar
    Y si no tiene ninguna se muestra "Aún no tienes publicaciones finalizadas."

  Escenario 3: Marcar como Reservado
    Dado que el estudiante acordó una entrega de su publicación Disponible
    Cuando abre "Gestionar publicación" (desde "Mis publicaciones" o desde el Detalle)
    Y elige "Marcar como Reservado"
    Entonces la publicación cambia a "Reservado"
    Y se muestra el mensaje "Tu publicación ahora está Reservada."
    Y en el Feed aparece con la etiqueta "Reservado"
    Y otros estudiantes ven el botón "Contactar al vendedor" deshabilitado

  Escenario 4: Volver a Disponible
    Dado que el estudiante tiene una publicación Reservada
    Y el trato no se concretó
    Cuando elige "Volver a Disponible"
    Entonces la publicación cambia a "Disponible"
    Y otros estudiantes pueden volver a contactarlo

  Escenario 5: Marcar como Vendido con confirmación
    Dado que el estudiante completó la entrega de una publicación Disponible o Reservada
    Cuando elige "Marcar como Vendido"
    Entonces se pide confirmar con el aviso "Ya no podrás cambiar su estado ni editarla."
    Cuando confirma
    Entonces la publicación cambia a "Vendido"
    Y sale del Feed público
    Y pasa a la pestaña "Finalizadas"
    Cuando en lugar de confirmar presiona "Cancelar"
    Entonces la publicación no cambia

  Escenario 6: Editar una publicación Disponible
    Dado que el estudiante tiene una publicación Disponible
    Cuando elige "Editar"
    Entonces ve el formulario de "Publicar artículo" con los datos actuales y sus fotos
    Cuando cambia el título, la descripción, la categoría, la modalidad, el precio o las fotos
    Y presiona "Guardar cambios"
    Entonces el sistema guarda los cambios
    Y las fotos que quitó se borran del almacenamiento
    Y regresa a la pantalla anterior mostrando los datos actualizados

  Escenario 7: Editar con datos inválidos
    Dado que el estudiante está editando su publicación
    Cuando deja datos que no cumplen las reglas de HU-03
      (por ejemplo, elige "Venta" sin precio o quita todas las fotos)
    Y presiona "Guardar cambios"
    Entonces el sistema no envía los cambios
    Y cada campo muestra el mismo mensaje que en "Publicar artículo"

  Escenario 8: Borrar una publicación Disponible
    Dado que el estudiante tiene una publicación Disponible
    Cuando elige "Borrar publicación"
    Entonces se pide confirmar con el aviso "Se borrará la publicación y sus fotos. No se puede deshacer."
    Cuando confirma
    Entonces la publicación y sus fotos se borran
    Y desaparece de "Mis publicaciones" y del Feed
    Y se muestra el mensaje "Publicación borrada."

  Escenario 9: Acción no permitida por el estado
    Dado que la publicación del estudiante está Reservada o Vendida
    Cuando abre "Gestionar publicación"
    Entonces solo ve las acciones que su estado permite (ver la tabla del patrón State)
    Y si la publicación cambió de estado en otro dispositivo y elige una acción que ya no es válida
    Entonces el servidor la rechaza
    Y se muestra "Esa acción ya no es posible: la publicación cambió de estado."
    Y la gestión se recarga con el estado actual

  Escenario 10: Publicación de otro estudiante
    Dado que el estudiante abre el detalle de una publicación de otro estudiante
    Entonces no aparece "Gestionar publicación"
    Y si alguien intenta cambiar, editar o borrar esa publicación saltándose la app
    Entonces el servidor no modifica nada
    Y la app muestra "No tienes permiso para modificar esta publicación."

  Escenario 11: Sin publicaciones
    Dado que el estudiante nunca ha publicado
    Cuando entra a "Mis publicaciones"
    Entonces se muestra "Aún no tienes publicaciones activas."
    Y el botón "Publicar artículo" lo lleva a la pantalla de publicar

  Escenario 12: Sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando intenta cargar sus publicaciones, cambiar un estado, editar o borrar
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra "Sin conexión a internet. Verifica tu red e inténtalo de nuevo."
    Y la publicación y los datos que había escrito se conservan

  Escenario 13: Error del servidor
    Dado que el servidor responde con un error
    Cuando el estudiante carga sus publicaciones, cambia un estado, edita o borra
    Entonces se muestra "No pudimos completar la acción. Inténtalo de nuevo."
      (o "No pudimos cargar tus publicaciones. Inténtalo de nuevo." al cargar)
    Y el mensaje no revela detalles internos (tablas, reglas ni direcciones)
    Y no queda nada a medias: si al editar falla el guardado, se borran las fotos nuevas que se alcanzaron a subir

  Escenario 14: El Feed y el Detalle se actualizan
    Dado que el estudiante cambió el estado, editó o borró una publicación
    Cuando regresa al Detalle o al Feed
    Entonces el Detalle muestra el estado y los datos nuevos
    Y en el Feed la tarjeta se actualiza (Reservado), desaparece (Vendido o borrada)
      sin tener que jalar para actualizar
```

**Reglas de negocio** (las revisa la app y también la base de datos):

- Solo el **dueño** puede cambiar el estado, editar o borrar una publicación.
- Cambios de estado permitidos (patrón State): **Disponible → Reservado o Vendido**, **Reservado → Disponible o Vendido**. **Vendido es final.**
- Solo una publicación **Disponible** se puede **editar** o **borrar**.
- Al editar se aplican las mismas reglas de HU-03 (título 3-80, descripción 10-500, 1 a 5 fotos JPG/PNG de máx. 5 MB, Venta con precio mayor a $0).
- Al borrar una publicación o quitar una foto al editar, la foto también se borra del almacenamiento.
- "Mis publicaciones" solo muestra las publicaciones del estudiante con sesión; la lista completa de otro estudiante (incluidas sus Vendidas) no se puede pedir.
- Páginas de **20** (máximo 50 por petición), de la más nueva a la más vieja.

### Relación escenario → prueba automática

| Escenario | Pruebas que lo cubren |
| :--- | :--- |
| 1. Activas | `obtener_mis_publicaciones_test` (Activas, cursor), `mis_publicaciones_cubit_test` (cargar, cargarMas), CP-36 (POST `rpc/mis_publicaciones` → 200, sin `p_finalizadas`), CP-37 (segunda página con cursor) |
| 2. Finalizadas | `obtener_mis_publicaciones_test` (Finalizadas), `mis_publicaciones_cubit_test` (cambiar pestaña; vacío), CP-37 (`p_finalizadas: true`) |
| 3. Reservar | `estado_publicacion_test` (acciones de Disponible), `cambiar_estado_publicacion_test`, `gestionar_publicacion_cubit_test` (reservar → Actualizada), CP-38 (PATCH solo con `{"estado":"reservado"}` → 200) |
| 4. Volver a Disponible | `estado_publicacion_test` (liberar), `cambiar_estado_publicacion_test`, `gestionar_publicacion_cubit_test` (liberar) |
| 5. Vender con confirmación | `estado_publicacion_test` (Vendido sin acciones), `gestionar_publicacion_cubit_test` (pide confirmación; cancelar no llama al servidor), CP-38 |
| 6. Editar | `editar_publicacion_test` (sube nuevas, guarda, borra quitadas), `publicacion_model_test` (`paraEditar` no manda dueño ni estado), `editar_publicacion_cubit_test` (`PublicacionCubit` en modo edición), CP-40 (PATCH → 200), CP-47 (fotos) |
| 7. Editar inválido | `publicacion_validator_test` (reutilizado), `editar_publicacion_test` (no llama al servidor), `editar_publicacion_cubit_test` (errores por campo) |
| 8. Borrar | `borrar_publicacion_test` (borra la fila y luego sus fotos), `gestionar_publicacion_cubit_test` (pide confirmación), CP-42 (DELETE → 200 y Storage borra las fotos) |
| 9. No permitida | `estado_publicacion_test` (transiciones inválidas lanzan `TransicionNoPermitidaFailure`), `cambiar_estado_publicacion_test` (no llama al servidor), CP-39 (400 `transicion_no_permitida`), CP-41 (400 `publicacion_no_editable`, y reglas de HU-03 si se salta la app); además la base lo bloquea |
| 10. De otro estudiante | `detalle_publicacion_cubit_test` (sin "Gestionar" si no es mía), CP-43 (0 filas o 403 → sin permiso, no se borran fotos; id inválido → ya no existe); además RLS lo bloquea |
| 11. Sin publicaciones | `mis_publicaciones_cubit_test` (lista vacía → Vacío) |
| 12. Sin conexión | todos los casos de uso, los tres Cubits (conservan los datos), CP-45 (ninguna petición) |
| 13. Error del servidor | los tres Cubits, CP-44 (500 → mensaje genérico, sin IP ni nombres internos), CP-47 (si falla el guardado se borran las fotos nuevas) |
| 14. Feed y Detalle se actualizan | `feed_cubit_test` (`sincronizar` reemplaza o quita la tarjeta), `detalle_publicacion_cubit_test` (recarga y avisa con `alCambiar`) |

Otra prueba del API: CP-46 (sin sesión no se hace ninguna petición).

**Pruebas de la base de datos:** la migración se probó en un Postgres 16 local con el stub de Auth y Storage: **42 casos, todos pasan** (entre ellos, que un estudiante no puede editar, cambiar el estado ni borrar la publicación de otro, ni borrar sus fotos).

## 6. Definición de Hecho (Definition of Done) del Sprint 6

- [ ] Las 5 decisiones de la sección 3 confirmadas por los Product Owners; issue #1 reabierto y actualizado con estos criterios.
- [ ] Diseño de "Mis publicaciones" y "Gestionar publicación" en Figma antes de programar las pantallas.
- [ ] Código en `feature/HU-06-mis-publicaciones`, con commits siguiendo Conventional Commits.
- [ ] Migración `20261029120000_hu06_mis_publicaciones.sql` aplicada en Supabase **el mismo día** y comprobada con la consulta del final del archivo (3 filas con "sí").
- [ ] Ya no aparece "En desarrollo" en "Mis publicaciones" (Mi perfil) ni en "Gestionar publicación" (Detalle).
- [ ] Los 14 escenarios Gherkin de la sección 5 pasan manualmente contra el build (validación de Jesus).
- [ ] Cada escenario Gherkin tiene al menos una prueba automática y todas las pruebas pasan (`flutter test`), incluidas las de HU-01 a HU-05.
- [ ] `flutter analyze` sin errores ni avisos (ni siquiera "info").
- [ ] Quality Gate de cobertura (≥ 80 % en dominio y datos) y Quality Gate de SonarQube Cloud en verde.
- [ ] Pull Request hacia `develop` con la plantilla completa, **al menos 1 aprobación registrada** y CI en estado PASSED antes del merge (Squash and Merge). El PR menciona el issue #1 (`Closes #1`).
- [ ] Guía de diseño (`docs/Sprint6_Guia_Diseno.md`) entregada a Oziel.
- [ ] Protección de `develop` configurada para exigir 1 aprobación.
- [ ] PR #29 `develop` → `main` fusionado.
- [ ] Demo en la Sprint Review del viernes: Mi perfil → Mis publicaciones → Reservar (el Feed muestra "Reservado" y el Detalle de otro usuario deshabilita "Contactar") → Volver a Disponible → Editar el precio → Marcar como Vendido (confirmación) → pestaña Finalizadas → Borrar una Disponible → modo avión para mostrar el mensaje de sin conexión.

## 7. Riesgos específicos del sprint

- **Sprint de 2 días:** el trabajo empezó el jueves 29 y la Review es el viernes 30. Mitigación: la base de datos ya está probada y la lógica se entrega el jueves; si "Editar" no alcanza, se entrega lo demás (Mis publicaciones, Reservar, Liberar, Vender y Borrar) y "Editar" pasa al Sprint 7, avisándolo en la Review. Los PO pueden decidir mover la Review si el calendario de la materia lo permite.
- **Día de Muertos (lunes 2 de noviembre):** no es día de descanso obligatorio por ley, pero muchas escuelas suspenden actividades. Mitigación: Jose Luis confirma con el calendario de la UTSJR si el Sprint 7 empieza el lunes 2 o el martes 3, y en ese caso la planeación del Sprint 7 se hace el martes.
- **El servidor no avisa cuando la publicación es de otro:** con las reglas RLS, intentar cambiar o borrar una publicación ajena no da error, simplemente no modifica nada (0 filas). Mitigación: la app pide de regreso la fila modificada; si no llega nada, muestra "No tienes permiso para modificar esta publicación." (CP-43).
- **Fotos sueltas en el almacenamiento:** si se borra la publicación pero falla el borrado de sus fotos, quedan archivos sin usar. Mitigación: primero se borra la publicación (lo importante) y después las fotos; si fallan, no se muestra error al estudiante y quedan para la limpieza propuesta en V5. Al editar, si falla el guardado se borran las fotos recién subidas (igual que en HU-03).
- **Dos dispositivos con la misma cuenta:** el estudiante podría vender en el celular y luego intentar reservar desde la web. Mitigación: la base revisa la transición contra el estado real y la app muestra el mensaje del Escenario 9 y recarga.
- **Volver a correr migraciones viejas:** la de HU-06 reemplaza la función del trigger de HU-03; si alguien vuelve a correr la de HU-03, se pierden las reglas de editar y borrar. Además, la de HU-04 ya no se puede volver a correr (desde el Sprint 5 la búsqueda depende de la vista). Mitigación: solo se corre la migración nueva de cada sprint; está anotado en el encabezado del archivo.
- **App vieja instalada:** los APK de los Sprints 3 a 5 no editan ni borran, y `feed_publicaciones` y `buscar_publicaciones` no se tocaron. No se agrega ningún estado nuevo, así que no hay valores que la app vieja no conozca.
- **Choque con el diseño:** Oziel tiene pendiente el diseño de búsqueda y filtros en `feed_page.dart`, y HU-06 toca `detalle_publicacion_page.dart` y `mi_perfil_page.dart`. Mitigación: HU-06 no modifica `feed_page.dart`; Oziel solo modifica `presentation/pages/`, `presentation/widgets/` y `core/theme/`, y siempre conserva las Keys.
- **Fusiones sin aprobación:** los PR #30 y #31 se fusionaron sin aprobación registrada y `develop` no tiene protección. Mitigación: configurar la protección antes de abrir el PR de HU-06.

## 8. Seguridad

HU-06 sigue los principios del Sprint 3 (marcados con `SEGURIDAD:` en el código):

- **No confiar en el cliente:** la app nunca manda el dueño; al cambiar de estado solo manda el estado nuevo y la base revisa que la transición sea válida contra el estado real.
- **Mínimo privilegio:** solo el dueño cambia, edita o borra (RLS de HU-03); solo borra fotos de su carpeta (Storage). La función `mis_publicaciones` toma al dueño de la sesión, no de un parámetro, así que nadie puede pedir la lista completa de otro estudiante. El rol `anon` no puede llamarla.
- **Mediación completa:** la función corre con los permisos de quien la llama (`security invoker`), así que el RLS se sigue aplicando.
- **Defensa en profundidad:** la regla "solo Disponible se edita o se borra" está en el dominio (patrón State), en el Cubit (no muestra la acción) y en la base (trigger).
- **Fallar de forma segura:** si el guardado falla no quedan fotos nuevas sueltas; los errores llegan con mensajes en español sin detalles internos (la base manda una pista fija, no el texto del error).
- **Disponibilidad:** nadie puede pedir más de 50 publicaciones por petición.

Siguen pendientes para sprints posteriores: V1 (dominio institucional solo en la app), V2 (fotos públicas y metadatos GPS), V3 (sesión sin cifrar y `allowBackup`) y V5 (sin límite de publicaciones; ahora también limpieza de fotos sueltas).

## 9. Pendientes arrastrados del Sprint 5

Estado revisado en GitHub el jueves 29 de octubre:

| Pendiente | Responsable | Rama / acción | Estado |
| :--- | :--- | :--- | :--- |
| Reabrir el issue #1 (sigue **cerrado** desde el 30 de septiembre), actualizar el #5 y crear el issue "HU-04: Feed de Publicaciones" | Diaz Huerta Diego Oziel | GitHub Issues | Pendiente |
| Aprobar y fusionar el PR #29 `develop` → `main` (abierto desde el 9 de octubre, sin aprobaciones; último merge a `main`: PR #22) | Orduña Garrido Jose Luis | PR `develop` → `main` | Pendiente |
| Exigir 1 aprobación en `develop` (hoy la rama **no tiene protección**; los PR #30 y #31 se fusionaron sin aprobación) | Orduña Garrido Jose Luis y Gonzalez Casarrubias Luis Angel | Configuración del repo | Pendiente |
| Diseño del buscador, los filtros y "Sin resultados" según Figma | Diaz Huerta Diego Oziel | Rama de diseño desde `develop` | Pendiente |
| Validación manual: hoja de filtros, sin conexión y casos pendientes de HU-01 a HU-04 | Torres Valeriano Jesus | Checklist de validación con capturas | Pendiente |
| Confirmar con Servicios Escolares el acomodo carrera → división | Oziel y Jesus | Si cambia algo, Jonathan prepara una migración y Jose Luis la aplica | Pendiente |
| Cargar publicaciones de prueba de varias carreras | Cadena Vega Jonathan | Datos de prueba en Supabase | Pendiente |
| Permiso de galería en iPhone (`NSPhotoLibraryUsageDescription`) | Gonzalez Casarrubias Luis Angel | `chore/plataformas-flutter` (falta la carpeta `ios/`) | Pendiente |

**Orden sugerido de fusión a `develop`:** `feature/HU-06-mis-publicaciones` (base de datos, lógica, pantallas y pruebas) → ajustes de diseño de Oziel (HU-05 y HU-06) → `chore/plataformas-flutter` cuando esté lista la carpeta `ios/`. Después de la Review: `develop` → `main`.
