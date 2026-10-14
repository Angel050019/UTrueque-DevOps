# Guía de diseño - HU-04 Feed de publicaciones (Sprint 4)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

El Feed y el Detalle de la publicación ya funcionan y usan la paleta del logo y los widgets compartidos (`PrimaryButton`, `SecondaryButton`, `BarraSuperior`, `mostrarMensaje`, `AvatarPerfil`). Tu trabajo es revisarlos contra Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Las pantallas

| Pantalla | Archivo | Ruta | Cuándo aparece |
| :--- | :--- | :--- | :--- |
| Feed | `features/feed/presentation/pages/feed_page.dart` | `/feed` | Después del login (perfil completo), al publicar y al volver de cualquier pantalla. |
| Detalle de la publicación | `features/publicaciones/presentation/pages/detalle_publicacion_page.dart` | `/publicacion` | Al tocar una tarjeta del Feed o "Ver publicación" en la confirmación de HU-03. |

Todas las rutas de archivo son relativas a `app/lib/`.

**Feed, de arriba hacia abajo:** saludo y avatar (abre "Mi perfil") → buscador → filtros → "Publicaciones recientes" → lista de tarjetas → al final de la lista: spinner (cargando más), "Ya viste todas las publicaciones." o error con "Reintentar". Botón flotante "Publicar". El buscador y los filtros **todavía no funcionan** (Sprint 5); puedes diseñarlos, pero no les agregues lógica.

**Detalle, de arriba hacia abajo:** barra con regreso → carrusel de fotos con indicador "1 de N" → etiquetas (categoría, estado y "Es tu publicación") → título → precio o modalidad → aviso si está Reservado o Vendido → "Publicado el 13 de octubre de 2026" → descripción → "Publicado por" (foto, nombre, carrera y división del dueño) → botón fijo abajo: "Contactar al vendedor" o, si es mía, "Gestionar publicación".

Piezas que puedes ajustar:

| Pieza | Dónde | Para qué sirve |
| :--- | :--- | :--- |
| `TarjetaPublicacion` | `features/publicaciones/presentation/widgets/tarjeta_publicacion.dart` | Cada artículo del Feed. |
| `EtiquetaPublicacion` | `features/publicaciones/presentation/widgets/etiqueta_publicacion.dart` | Etiquetas redondas de precio, modalidad, categoría y estado (Feed y Detalle). |
| `AvisoPantalla` | `core/widgets/aviso_pantalla.dart` | Avisos a pantalla completa: Feed vacío, sin conexión, error y "ya no está disponible" (Feed y Detalle). |
| `_FinDeLista` | `feed_page.dart` | Lo que se ve al final de la lista. |
| `_Carrusel` | `detalle_publicacion_page.dart` | Fotos que se deslizan con el indicador "1 de N". |
| `_TarjetaDueno` | `detalle_publicacion_page.dart` | Datos públicos del dueño. |
| `_Acciones` | `detalle_publicacion_page.dart` | Botón de abajo (Contactar / Gestionar). |

Si una pieza crece mucho, puedes sacarla a su propio archivo dentro de `presentation/widgets/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

---

## 2. Estados de los Cubits

### Feed (`FeedCubit`)

| Estado | Qué mostrar |
| :--- | :--- |
| `FeedCargando` | Indicador de carga |
| `FeedCargado` | La lista. Al final: spinner si `cargandoMas`, el mensaje `errorMas` con "Reintentar" si no es `null`, o "Ya viste todas las publicaciones." si `hayMas` es `false` |
| `FeedVacio` | "Aún no hay publicaciones" + "¡Sé el primero en publicar!" |
| `FeedError` | Pantalla de error con `state.mensaje` y "Reintentar". `state.sinConexion` te dice si es por falta de internet (para cambiar ícono o ilustración) |

Si `FeedCargado.aviso` no es `null` (por ejemplo, al jalar para actualizar sin internet), la página ya muestra un SnackBar con ese texto; la lista se conserva.

### Detalle (`DetallePublicacionCubit`)

| Estado | Qué mostrar |
| :--- | :--- |
| `DetalleCargando` | Indicador de carga |
| `DetalleCargado` | La publicación. `state.esMia` → etiqueta "Es tu publicación" y botón "Gestionar". `state.puedeContactar` → si es `false`, el botón "Contactar al vendedor" va deshabilitado. `publicacion.estado.aviso` → texto del aviso de Reservado o Vendido (`null` si está Disponible) |
| `DetalleNoEncontrado` | `state.mensaje` ("Esta publicación ya no está disponible.") y "Volver al Feed" |
| `DetalleError` | `state.mensaje` y "Reintentar" |

Los textos **ya vienen en español** desde la lógica (`state.mensaje`, `estado.aviso`, `estado.etiqueta`). No escribas los tuyos.

Datos que tienes en `publicacion` para dibujar: `titulo`, `descripcion`, `categoriaNombre`, `modalidad.etiqueta`, `precio` (usa `formatearPrecio`), `estado.etiqueta`, `creadaEn` (usa `formatearFecha`), `portadaUrl`, `fotosUrls`, `duenoNombre`, `duenoFotoUrl`, `duenoDivision` y `duenoCarrera`.

---

## 3. Qué método llama cada acción

| Acción | Llamada |
| :--- | :--- |
| Reintentar la carga del Feed | `context.read<FeedCubit>().cargar()` |
| Jalar para actualizar el Feed | `context.read<FeedCubit>().actualizar()` (ya está en el `RefreshIndicator`) |
| Cargar más / reintentar cargar más | `context.read<FeedCubit>().cargarMas()` (ya se llama solo al acercarse al final) |
| Abrir el detalle desde una tarjeta | Ya está en `_abrirDetalle` de `feed_page.dart`; reutilízalo |
| Reintentar o actualizar el Detalle | `context.read<DetallePublicacionCubit>().cargar()` |
| Volver al Feed | `Navigator.of(context).maybePop()` |
| Contactar / Gestionar | Ya están en `_Acciones` (abren "En desarrollo"); reutilízalos |

---

## 4. Qué archivos puedes modificar

✅ **Sí:**

- `features/feed/presentation/pages/feed_page.dart`
- `features/publicaciones/presentation/pages/detalle_publicacion_page.dart`
- `features/publicaciones/presentation/widgets/` (incluida `tarjeta_publicacion.dart`; menos la lógica de `elegir_fotos_articulo.dart`)
- `core/theme/app_theme.dart` y `core/widgets/aviso_pantalla.dart`
- `assets/` si necesitas ilustraciones (avísanos para registrarlas en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `presentation/cubit/` de cualquier feature (estados y Cubits)
- `features/feed/presentation/feed_keys.dart`, `features/publicaciones/presentation/detalle_keys.dart` y `publicacion_keys.dart`
- `domain/` y `data/` de cualquier feature
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 5. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo. Así las pruebas siguen funcionando aunque cambie el diseño.

**Feed (`FeedKeys`):**

| Key | Widget |
| :--- | :--- |
| `publicarBoton` | Botón flotante "Publicar" |
| `miPerfilBoton` | Avatar que abre "Mi perfil" |
| `lista` | La lista de publicaciones |
| `cargando` | Indicador de la primera carga |
| `vacio` | Pantalla de Feed vacío |
| `error` / `reintentarBoton` | Pantalla de error y su botón |
| `cargandoMas` | Spinner al final de la lista |
| `finDeLista` | "Ya viste todas las publicaciones." |
| `errorMas` / `reintentarMasBoton` | Error al cargar más y su botón |
| `PublicacionKeys.tarjeta(id)` | Cada tarjeta (está en `publicacion_keys.dart`) |

**Detalle (`DetalleKeys`):**

| Key | Widget |
| :--- | :--- |
| `pantalla` | El `Scaffold` del Detalle |
| `cargando` | Indicador de carga |
| `error` / `reintentarBoton` | Error y su botón |
| `noEncontrado` / `volverFeedBoton` | "Ya no está disponible" y su botón |
| `carrusel` / `indicadorFotos` | Carrusel de fotos y el "1 de N" |
| `titulo`, `precioOModalidad`, `estado`, `avisoEstado`, `fecha`, `descripcion` | Los datos de la publicación |
| `dueno` | Tarjeta del dueño |
| `esMiaEtiqueta` | Etiqueta "Es tu publicación" |
| `contactarBoton` / `gestionarBoton` | Botón de abajo |

Las Keys del Feed que había en `PublicacionKeys` (Sprint 3) se movieron a `FeedKeys` con los mismos valores.

---

## 6. Cómo probarlo

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

- **Feed con datos:** entra con una cuenta con perfil completo.
- **Cargar más:** se necesitan más de 20 publicaciones; si no hay tantas, pídele a Jonathan que cargue datos de prueba.
- **Feed vacío o sin conexión:** en Chrome, `F12` → pestaña *Network* → *Offline* y presiona "Reintentar" o jala para actualizar.
- **Reservada / Vendida:** pídele a Jose Luis que cambie el `estado` de una publicación de prueba en Supabase y abre su detalle.
- **Mi publicación:** abre el detalle de una publicación que hayas creado tú.

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-04-feed-publicaciones`; usa commits `style(feed): ...` o `style(publicaciones): ...` y adjunta capturas del Feed (con datos, vacío y sin conexión) y del Detalle (disponible, reservado, mío y "ya no está disponible") en el PR.
