# Seguridad de UTrueque - Insumos para las actividades de la Unidad 2, Tema 1

Para: **Torres Valeriano Jesus** (arma la entrega)
De: Equipo de Desarrollo
Materia: Desarrollo Móvil Integral · Tema: *Especificación de principios de codificación segura*
Entrega: **jueves 15 de octubre de 2026**, en PDF y con portada, con las 3 actividades en un solo documento.

Este documento **no es la entrega**: es el material del proyecto para que la armes. Todo lo que dice aquí está en el código o en la base de datos de `develop` + la rama `feature/HU-03-publicar-articulo`.

En el código, los puntos de seguridad están marcados con el comentario `SEGURIDAD:`. Para verlos todos en VS Code: `Ctrl+Shift+F` → `SEGURIDAD:`.

---

## Actividad 1 · Preguntas de recolección de datos

### 1.1 ¿Qué datos recolectamos? (listado y clasificación)

| Dato | Dónde se captura | Clasificación |
| :--- | :--- | :--- |
| Correo institucional (`@utsjr.edu.mx`) | Registro / Inicio de sesión (HU-01) | Personal (identifica al estudiante) |
| Contraseña | Registro / Inicio de sesión (HU-01) | Credencial (la app no la guarda; Supabase Auth guarda solo su *hash*) |
| Nombre a mostrar | Completar perfil (HU-02) | Personal |
| División y carrera | Completar perfil (HU-02) | Personal, no sensible |
| Foto de perfil (opcional) | Completar / Editar perfil (HU-02) | Personal (imagen que puede identificar a la persona) |
| Publicación: título, descripción, categoría, modalidad, precio | Publicar artículo (HU-03) | Datos del artículo, no personales |
| Fotos del artículo | Publicar artículo (HU-03) | Pueden traer datos personales sin querer (caras, documentos al fondo, ubicación GPS en los metadatos) |
| Sesión (token de acceso) | Automático al iniciar sesión | Credencial temporal |

UTrueque **no pide datos sensibles** (salud, religión, origen, finanzas personales, etc.) ni la ubicación del celular.

### 1.2 Tabla de decisiones

| Pregunta | Decisión documentada para UTrueque |
| :--- | :--- |
| **¿Qué datos recolectamos?** | Los de la tabla 1.1. Solo lo necesario para que un estudiante se identifique y publique artículos. |
| **¿Para qué los necesitamos?** | Correo: comprobar que es estudiante de la UTSJR. Contraseña: autenticación. Nombre y foto: que los compañeros sepan con quién tratan. División y carrera: filtrar publicaciones. Datos del artículo: mostrarlo en el Feed. Token: no pedir la contraseña en cada pantalla. |
| **¿Qué pasa si no lo recolectamos?** | Sin correo institucional no hay forma de garantizar un marketplace cerrado a la UTSJR. Sin división/carrera no hay filtrado (diferenciador del producto). **La foto de perfil es opcional** (minimización): la app funciona sin ella. No pedimos teléfono, dirección, CURP ni matrícula porque no hacen falta. |
| **¿Dónde se almacenan?** | En **Supabase** (servicio en la nube de un tercero): correo y contraseña en *Supabase Auth*; perfil y publicaciones en *Postgres* (tablas `usuarios` y `publicaciones`); fotos en *Storage* (buckets `avatars` y `publicaciones`). En el celular solo queda la sesión. Las llaves del proyecto viven en `env.json` (fuera del repositorio) y en GitHub Secrets. |
| **¿Quién puede acceder?** | **Estudiante autenticado:** lee perfiles públicos y publicaciones. **Dueño:** es el único que puede crear, editar o borrar su perfil, sus publicaciones y sus fotos (reglas RLS y de Storage). **Equipo (rol `service_role` en el panel de Supabase):** administra catálogos. **Visitante sin cuenta:** no puede leer tablas; ver la vulnerabilidad V2 sobre las fotos. |
| **¿Cuándo se eliminan?** | Si se borra la cuenta en Supabase Auth, el perfil y sus publicaciones se borran en cascada. Si una publicación no se puede guardar, la app borra las fotos que alcanzó a subir. **Pendiente:** no existe todavía un botón "Eliminar mi cuenta" ni un plazo de retención; se propone para un sprint posterior (derechos ARCO: Cancelación). |

---

## Actividad 2 · Auditoría de vulnerabilidades

La actividad pide **una vulnerabilidad por integrante**. Estas son 5 propuestas reales del proyecto; repártanlas entre ustedes y llenen el punto 1 (integrante) con quien la explique.

### V1 · El dominio institucional solo se valida en la app

| Punto | Respuesta |
| :--- | :--- |
| 1. Integrante | *(por asignar)* |
| 2. Vulnerabilidad | La regla "solo correos `@utsjr.edu.mx`" se revisa en la app (`EmailValidator`), pero el API de registro de Supabase (`POST /auth/v1/signup`) acepta cualquier correo. La llave pública (anon key) viaja dentro de la app, así que alguien puede llamar al API directamente. |
| 3. Ubicación | `app/lib/core/utils/email_validator.dart`, caso de uso `RegistrarUsuario` y configuración de Supabase Auth. |
| 4. Riesgo | Una persona ajena a la UTSJR crea una cuenta con Gmail y entra al marketplace "cerrado". |
| 5. Impacto | Se pierde la promesa principal del producto (comunidad confiable); posibles fraudes o acoso a estudiantes. |
| 6. Mitigación | Validar también en el servidor: un *Auth Hook* o un trigger en `auth.users` que rechace correos que no terminen en `@utsjr.edu.mx`, y mantener obligatoria la confirmación del correo. (Principio: **no confiar en el cliente**.) |

### V2 · Fotos accesibles sin cuenta y con metadatos

| Punto | Respuesta |
| :--- | :--- |
| 1. Integrante | *(por asignar)* |
| 2. Vulnerabilidad | Los buckets `avatars` y `publicaciones` son públicos para lectura: quien tenga el enlace de una foto la ve sin iniciar sesión. Además, las fotos tomadas con el celular pueden traer metadatos (EXIF) con la ubicación GPS donde se tomaron. |
| 3. Ubicación | Migraciones `supabase/migrations/*hu02*` y `*hu03*` (sección Storage); `elegir_fotos_articulo.dart`. |
| 4. Riesgo | Las fotos de perfil y de artículos se pueden compartir fuera de la universidad; una foto tomada en casa podría revelar el domicilio. |
| 5. Impacto | Privacidad de los estudiantes (imagen y ubicación). |
| 6. Mitigación | Ya aplicado en HU-03: la app pide a la galería una copia reducida (1920 px, calidad 85), lo que vuelve a codificar la imagen. Pendiente: confirmar que la copia ya no trae GPS en Android e iOS (Jesus puede probarlo con una foto con ubicación) y evaluar buckets privados con URLs firmadas. |

### V3 · Sesión guardada sin cifrar y respaldos de Android

| Punto | Respuesta |
| :--- | :--- |
| 1. Integrante | *(por asignar)* |
| 2. Vulnerabilidad | Supabase guarda la sesión (token) en el almacenamiento normal del celular, sin cifrar. El `AndroidManifest.xml` no desactiva `allowBackup`, así que esos datos pueden ir en los respaldos del teléfono. |
| 3. Ubicación | `app/lib/main.dart` (`Supabase.initialize`) y `app/android/app/src/main/AndroidManifest.xml`. |
| 4. Riesgo | En un teléfono con root o desde un respaldo, alguien copia el token y entra como el estudiante. |
| 5. Impacto | Suplantación: publicar, editar o borrar a nombre de otro mientras el token sea válido. |
| 6. Mitigación | Guardar la sesión con `flutter_secure_storage` (Keystore/Keychain) y agregar `android:allowBackup="false"`. Tokens de vida corta (ya: 1 hora). |

### V4 · Confiar en lo que manda la app al publicar (MITIGADA en HU-03)

| Punto | Respuesta |
| :--- | :--- |
| 1. Integrante | *(por asignar)* |
| 2. Vulnerabilidad | Si la base de datos aceptara lo que manda la app, alguien podría modificar la petición `POST /rest/v1/publicaciones` para crear un artículo **a nombre de otro**, nacer como "Vendido", poner precio 0 en Venta o usar fotos de la carpeta de otro estudiante (mismo caso que el `?id=124` de la clase). |
| 3. Ubicación | Tabla `publicaciones` y bucket `publicaciones`. |
| 4. Riesgo | Publicaciones falsas a nombre de otro, precios inválidos, robo de fotos. |
| 5. Impacto | Integridad de las publicaciones y reputación de los estudiantes. |
| 6. Mitigación (aplicada) | 1) La app **no envía** `usuario_id` ni `estado`. 2) RLS: solo se crea a nombre propio y solo con perfil completo; solo el dueño edita o borra. 3) Trigger: toda publicación nace en Disponible, no se puede cambiar de dueño, los cambios de estado siguen el patrón State y las fotos deben estar en la carpeta del dueño. 4) Restricciones: precio > 0 en Venta, de 1 a 5 fotos. 5) Storage: 5 MB y solo JPG/PNG, escritura solo en la carpeta propia. Evidencia en la sección 4. |

### V5 · Sin límite de publicaciones ni de subidas

| Punto | Respuesta |
| :--- | :--- |
| 1. Integrante | *(por asignar)* |
| 2. Vulnerabilidad | Un usuario puede crear publicaciones y subir fotos sin límite. |
| 3. Ubicación | Tabla `publicaciones` y bucket `publicaciones`. |
| 4. Riesgo | Spam en el Feed o un script que llene el almacenamiento del plan gratuito de Supabase. |
| 5. Impacto | Disponibilidad: el Feed se vuelve inútil o Storage se llena y nadie más puede subir fotos. |
| 6. Mitigación | Límite por estudiante (por ejemplo, 20 publicaciones por día) con un trigger, y borrar fotos huérfanas con una tarea programada. |

---

## Actividad 3 · Matriz de seguridad de UTrueque

| Elemento | UTrueque |
| :--- | :--- |
| **Datos personales que maneja** | Correo institucional, contraseña (solo hash en Supabase Auth), nombre a mostrar, división, carrera, foto de perfil opcional, fotos de artículos y token de sesión. Sin datos sensibles. |
| **3 vulnerabilidades potenciales** | V1 dominio institucional validado solo en la app; V2 fotos accesibles sin cuenta y con posible ubicación GPS; V3 sesión sin cifrar y respaldos de Android. (V4 ya mitigada; V5 como reserva.) |
| **Principios de codificación que aplicarán** | **No confiar en el cliente:** la base revisa de nuevo cada regla (RLS, triggers, checks). **Mínimo privilegio:** cada estudiante solo escribe en sus filas y en su carpeta; el catálogo solo lo edita el equipo. **Secure by default:** RLS activo en todas las tablas; toda publicación nace Disponible; buckets con límite de 5 MB y solo JPG/PNG. **Fallar de forma segura:** si algo falla no se guarda nada a medias (se borran las fotos subidas) y el usuario ve un mensaje genérico. **Mediación completa:** RLS revisa permisos en cada petición, no solo al iniciar sesión. **Defensa en profundidad:** validación en la app + restricciones + trigger + RLS + Storage. **Validación de entrada:** tipo, longitud, formato y rango (título 3-80, descripción 10-500, precio > 0 con máx. 2 decimales, foto validada por su firma y no por la extensión). **Secretos fuera del código:** llaves en `env.json` (en `.gitignore`) y GitHub Secrets. |
| **Mecanismo de protección de datos** | Datos en reposo en Supabase con RLS por usuario; contraseñas con hash (Supabase Auth); fotos separadas por carpeta de dueño; errores traducidos a mensajes que no revelan tablas, reglas ni IPs; no se escriben tokens ni contraseñas en logs. Propuesto: sesión en almacenamiento seguro (V3). |
| **Mecanismo para proteger el intercambio** | Todo viaja por **HTTPS (TLS)** a Supabase; cada petición lleva el token de sesión (`Authorization: Bearer ...`) y el servidor decide con él qué se permite. La anon key es pública por diseño: lo que protege los datos son las reglas RLS, no esconder la llave. |
| **¿Cómo comprobarán que funciona?** | 1) Pruebas automáticas en cada Pull Request (GitHub Actions): `publicaciones_api_rest_test.dart` (CP-08 a CP-17) y pruebas unitarias. 2) Quality Gate de cobertura y de SonarQube. 3) Pruebas de las reglas en el SQL Editor de Supabase (sección 4.2). 4) Validación manual de Jesus contra el build, con capturas. |

---

## 4. Evidencias para el documento

### 4.1 Pruebas automáticas relacionadas con seguridad

| Prueba | Qué demuestra |
| :--- | :--- |
| `CP-09` | La app no envía `usuario_id` ni `estado`; el servidor asigna el dueño y la publicación nace Disponible. Todas las peticiones llevan el token. |
| `CP-11` | Aunque alguien salte la app y mande precio 0, el API responde 400 y el mensaje no revela el nombre de la regla. |
| `CP-12` | Si el guardado falla, se borran las fotos ya subidas (fallar de forma segura). |
| `CP-13` | Con el perfil incompleto, el servidor bloquea la publicación (403 por RLS). |
| `CP-14` | Storage rechaza fotos de más de 5 MB (413). |
| `CP-16` | Sin sesión no se hace ninguna petición. |
| `CP-17` | Los errores 403/415/500 llegan como mensajes en español sin detalles internos (por ejemplo, sin la IP `10.0.0.8`). |
| `publicacion_validator_test` | Validación de longitud, formato y rango; una imagen GIF renombrada a `.jpg` se rechaza por su firma. |
| `estado_publicacion_test` | Un artículo Vendido no puede volver a Disponible (patrón State). |

### 4.2 Pruebas de reglas en Supabase (para capturas)

Pídele a Jose Luis acceso al SQL Editor después de aplicar la migración. Cambia los UUID por dos usuarios de prueba reales (A con perfil completo, B con perfil incompleto). Cada bloque se ejecuta **como si fuera ese usuario**:

```sql
-- Prueba 1: crear a nombre de B → debe fallar
-- ("new row violates row-level security policy")
begin;
set local role authenticated;
set local request.jwt.claim.sub = 'UUID-DEL-USUARIO-A';
insert into publicaciones (usuario_id, titulo, descripcion, categoria_id, modalidad, fotos)
values ('UUID-DEL-USUARIO-B', 'Prueba', 'Prueba de seguridad', 1, 'gratis',
        array['UUID-DEL-USUARIO-B/x.jpg']);
rollback;

-- Prueba 2: intentar que nazca "vendido" → se guarda como 'disponible'
begin;
set local role authenticated;
set local request.jwt.claim.sub = 'UUID-DEL-USUARIO-A';
insert into publicaciones (titulo, descripcion, categoria_id, modalidad, estado, fotos)
values ('Prueba', 'Prueba de seguridad', 1, 'gratis', 'vendido',
        array['UUID-DEL-USUARIO-A/x.jpg'])
returning usuario_id, estado;
rollback;

-- Prueba 3: Venta con precio 0 → debe fallar (publicaciones_precio_chk)
begin;
set local role authenticated;
set local request.jwt.claim.sub = 'UUID-DEL-USUARIO-A';
insert into publicaciones (titulo, descripcion, categoria_id, modalidad, precio, fotos)
values ('Prueba', 'Prueba de seguridad', 1, 'venta', 0, array['UUID-DEL-USUARIO-A/x.jpg']);
rollback;

-- Prueba 4: el usuario B (perfil incompleto) no puede publicar → debe fallar (RLS)
begin;
set local role authenticated;
set local request.jwt.claim.sub = 'UUID-DEL-USUARIO-B';
insert into publicaciones (titulo, descripcion, categoria_id, modalidad, fotos)
values ('Prueba', 'Prueba de seguridad', 1, 'gratis', array['UUID-DEL-USUARIO-B/x.jpg']);
rollback;
```

Corre cada prueba por separado y toma captura del resultado. El `rollback` final evita dejar datos de prueba. Estas mismas pruebas ya se corrieron en un Postgres local durante el desarrollo y dieron el resultado esperado.

### 4.3 Dónde está cada control en el código

| Control | Archivo |
| :--- | :--- |
| Reglas de la base (RLS, trigger, checks, bucket) | `supabase/migrations/20261007120000_hu03_publicaciones.sql` |
| Validación de entrada | `app/lib/features/publicaciones/domain/validators/publicacion_validator.dart` |
| Foto validada por su firma, no por la extensión | `app/lib/core/utils/formato_imagen.dart` |
| No enviar dueño ni estado | `app/lib/features/publicaciones/data/models/publicacion_model.dart` (`paraCrear`) |
| Errores sin detalles internos | `app/lib/features/publicaciones/data/datasources/publicacion_remote_datasource.dart` (`_traducir`) |
| Limpieza si algo falla | `app/lib/features/publicaciones/domain/usecases/subir_fotos_publicacion.dart` y `crear_publicacion.dart` |
| Secretos fuera del repositorio | `app/.gitignore` (`env.json`), `app/env.example.json`, GitHub Secrets |
