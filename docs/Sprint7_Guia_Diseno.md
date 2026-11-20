# Guía de diseño - HU-07 Chat directo (Sprint 7)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

El chat ya funciona en tiempo real y usa la paleta del logo y los widgets compartidos (`BarraSuperior`, `AvisoPantalla`, `PrimaryButton`, `AvatarPerfil`, `mostrarMensaje`). Tu trabajo es diseñarlo en Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Las pantallas

| Pantalla | Archivo | Ruta | Cuándo aparece |
| :--- | :--- | :--- | :--- |
| Chat | `features/chat/presentation/pages/chat_page.dart` | `/chat` | "Contactar al vendedor" en el Detalle, o al tocar una conversación de la bandeja. |
| Mensajes (bandeja) | `features/chat/presentation/pages/bandeja_page.dart` | `/mensajes` | Ícono de mensajes en el encabezado del Feed. |
| Ícono de mensajes con globo | `features/feed/presentation/pages/feed_page.dart` | — | Junto a la foto de perfil, arriba del Feed. |

Todas las rutas de archivo son relativas a `app/lib/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

**Ya no existe** el "En desarrollo" de "Contactar al vendedor".

**Chat, de arriba hacia abajo:** encabezado (regresar, foto y nombre del otro estudiante, título de la publicación) → mensajes (los míos a la derecha en azul marino, los del otro a la izquierda en azul claro, con la hora abajo; el más nuevo hasta abajo; al subir se cargan los anteriores) → campo de texto con el botón "Enviar". Si la publicación se vendió o se borró, en lugar del campo aparece el aviso de solo lectura.

**Mensajes (bandeja):** una fila por conversación con la portada de la publicación, el nombre del otro estudiante, la fecha (`09:05`, `Ayer` o `5 nov`), "Te interesa: …" o "Tu publicación: …", el último mensaje (con "Tú:" si es mío) y el globo menta de no leídos. Las filas con mensajes sin leer van en negritas.

---

## 2. Estados de los Cubits

### Chat (`ChatCubit`)

Todos los estados traen `state.conversacion` (para el encabezado).

| Estado | Qué mostrar |
| :--- | :--- |
| `ChatCargando` | Indicador de carga |
| `ChatError` | `state.mensaje` y "Reintentar". `state.sinConexion` dice si es por falta de internet |
| `ChatListo` | Los mensajes. Si `mensajes` está vacía, el texto de bienvenida. Arriba de todo: spinner si `hayAnteriores`, o `errorAnteriores` con "Reintentar". Abajo: el campo, o el aviso si `cerrada` |

Si `ChatListo.aviso` no es `null` (por ejemplo, sin conexión al enviar), la página ya muestra un SnackBar y **el texto escrito se conserva**. Mientras `enviando` es `true`, el botón muestra un spinner.

### Mensajes (`BandejaCubit`)

| Estado | Qué mostrar |
| :--- | :--- |
| `BandejaCargando` | Indicador de carga |
| `BandejaVacia` | `BandejaVacia.mensaje` ("Aún no tienes mensajes.") |
| `BandejaError` | `state.mensaje` y "Reintentar" |
| `BandejaCargada` | La lista de `conversaciones`, la más reciente primero |

### Globo del Feed (`NoLeidosCubit`)

Su estado es un número: cuántas conversaciones tienen mensajes sin leer. Con 0 no se muestra el globo; de 10 en adelante dice "9+" (`GloboNoLeidos`).

Los textos **ya vienen en español** desde la lógica. No escribas los tuyos.

---

## 3. Qué método llama cada acción

| Acción | Llamada |
| :--- | :--- |
| "Contactar al vendedor" | `contactarVendedor(context, publicacion)` (ya está en `_BotonContactar` del Detalle) |
| Enviar | `context.read<ChatCubit>().enviar(texto)`; si regresa `true`, se borra el campo (ya está en `_enviar`) |
| Cargar mensajes anteriores | `cubit.cargarAnteriores()` (ya se llama solo al subir) |
| Reintentar el chat | `cubit.abrir()` |
| Abrir una conversación de la bandeja | Ya está en `_abrir` de `BandejaPage`; reutilízalo |
| Jalar para actualizar la bandeja / Reintentar | `cubit.actualizar()` / `cubit.cargar()` |
| Abrir la bandeja desde el Feed | Ya está en `_irAMensajes` de `FeedPage`; reutilízalo |

---

## 4. Qué archivos puedes modificar

✅ **Sí:**

- `features/chat/presentation/pages/` (solo lo visual)
- `features/chat/presentation/widgets/` (`burbuja_mensaje.dart`, `globo_no_leidos.dart`)
- El ícono de mensajes en `features/feed/presentation/pages/feed_page.dart` (solo lo visual)
- El botón de `features/publicaciones/presentation/pages/detalle_publicacion_page.dart` (solo lo visual)
- `core/theme/app_theme.dart` y `core/widgets/aviso_pantalla.dart`
- `assets/` si necesitas ilustraciones (avísanos para registrarlas en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `features/chat/presentation/cubit/` y `features/chat/presentation/contactar_vendedor.dart`
- Los filtros del campo de texto (`inputFormatters`): son de seguridad
- `chat_keys.dart` y las demás Keys
- `domain/` y `data/` de cualquier feature
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 5. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo.

**Chat (`ChatKeys`):** `pantalla`, `encabezado`, `lista`, `cargando`, `error`, `reintentarBoton`, `bienvenida`, `cargandoAnteriores`, `errorAnteriores`, `reintentarAnterioresBoton`, `campoTexto`, `enviarBoton`, `cerradaAviso` y `burbuja(id)` en cada mensaje.

**Mensajes (`BandejaKeys`):** `pantalla`, `lista`, `cargando`, `vacia`, `error`, `reintentarBoton`, `conversacion(id)` en cada fila y `noLeidos(id)` en cada globo.

**Feed (`FeedKeys`):** `mensajesBoton` y `mensajesGlobo`. **Detalle:** `DetalleKeys.contactarBoton` sigue igual.

---

## 6. Cómo probarlo

El chat necesita **dos cuentas**. Puedes usar dos celulares, o un celular y Chrome:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

(o el botón **Run** de VS Code, que ya carga `env.json`).

- **Contactar:** con la cuenta A, abre una publicación Disponible de la cuenta B y presiona "Contactar al vendedor".
- **Tiempo real:** con las dos cuentas en la misma conversación, escribe desde una; el mensaje aparece en la otra sin refrescar.
- **Globo:** con la cuenta B en el Feed, escribe desde A; el globo del ícono de mensajes sube.
- **Solo lectura:** con B, marca la publicación como Vendida; en el chat de A aparece el aviso en lugar del campo.
- **Sin conexión:** `F12` → *Network* → *Offline* y trata de enviar: el texto se conserva.

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-07-chat`; usa commits `style(chat): ...` y adjunta en el PR capturas del chat (vacío, con mensajes y cerrado), de la bandeja (con y sin no leídos, y vacía) y del ícono con el globo.
