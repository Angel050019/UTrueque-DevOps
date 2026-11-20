# Guía de diseño - HU-05 Búsqueda y filtros (Sprint 5)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

El buscador, los chips y la hoja de filtros del Feed ya funcionan y usan la paleta del logo y los widgets compartidos (`PrimaryButton`, `SecondaryButton`, `AvisoPantalla`, `mostrarMensaje`). Tu trabajo es diseñarlos en Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Qué cambió en el Feed

| Pieza | Archivo | Qué hace |
| :--- | :--- | :--- |
| Buscador | `features/feed/presentation/pages/feed_page.dart` (`_Buscador`) | Campo de texto real. Busca solo cuando el estudiante deja de escribir (o presiona "buscar" en el teclado). La "x" borra el texto. |
| Botón de filtros | `feed_page.dart` (`_BotonFiltros`) | Abre la hoja de División → Carrera. Se pinta azul con ícono menta cuando hay división o carrera elegida. |
| Chips | `feed_page.dart` (`_ChipsFiltros` y `_Chip`) | "Mi carrera" (con ícono de birrete), el chip de la división o carrera elegida en la hoja (con "x"), "Todo" y una por categoría (salen de la base, ya no están fijas en la app). |
| Título de la lista | `feed_page.dart` | "Publicaciones recientes" sin filtros; "Resultados" y el botón "Limpiar filtros" con filtros. |
| Hoja de filtros | `features/feed/presentation/widgets/hoja_filtros.dart` | Selectores División y Carrera, botones "Quitar" y "Aplicar". Si no hay internet muestra un aviso con "Reintentar". |
| Sin resultados | `feed_page.dart` (`_ListaFeed`) con `core/widgets/aviso_pantalla.dart` | Ilustración (hoy un ícono), "Sin resultados", el mensaje y el botón "Limpiar filtros". |

Todas las rutas de archivo son relativas a `app/lib/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

**Ya no existe** el aviso "La búsqueda y los filtros estarán listos en el Sprint 5".

---

## 2. Cómo se comporta (para que el diseño lo refleje)

- **Al abrir la app** el chip **"Mi carrera"** aparece activo: el Feed muestra solo publicaciones de estudiantes de la carrera del perfil. Un toque lo quita y otro lo vuelve a poner. Debe verse claramente que hay un filtro puesto.
- Los filtros **se combinan**: texto + categoría + división/carrera.
- **Sin resultados** (hay filtros y nada coincide): ilustración + "No se encontraron artículos que coincidan con tu búsqueda." + "Limpiar filtros". Es distinto de **Feed vacío** (no hay ninguna publicación).
- La carrera **solo se puede elegir de la división elegida**; si cambias la división en la hoja, la carrera se limpia.
- Lo elegido en la hoja **solo se aplica al presionar "Aplicar"**.

---

## 3. Estados del `FeedCubit`

| Estado | Qué mostrar |
| :--- | :--- |
| `FeedCargando` | Indicador de carga (también al cambiar un filtro) |
| `FeedCargado` | La lista (igual que en HU-04: spinner, error o "Ya viste todas" al final) |
| `FeedVacio` | "Aún no hay publicaciones" + "¡Sé el primero en publicar!" (sin filtros) |
| `FeedSinResultados` | Ilustración + `FeedSinResultados.mensaje` + "Limpiar filtros" (con filtros) |
| `FeedError` | `state.mensaje` y "Reintentar" (conserva los filtros). `state.sinConexion` te dice si es por falta de internet |

**Todos** los estados traen:

- `state.filtros`: `texto`, `categoriaId`, `divisionId`, `carreraId`, `hayFiltros` y `filtraPorDivisionOCarrera`.
- `state.opciones`: `categorias`, `divisiones`, `miCarrera` y ayudas como `carrerasDe(divisionId)`, `nombreDivision(id)` y `nombreCarrera(id)`.

Los textos de error y de "sin resultados" **ya vienen en español** desde la lógica. No escribas los tuyos.

---

## 4. Qué método llama cada acción

Obtén el Cubit con `context.read<FeedCubit>()`.

| Acción | Llamada |
| :--- | :--- |
| Escribir en el buscador | `cubit.escribirBusqueda(texto)` (ya está en `onChanged`) |
| "Buscar" en el teclado | `cubit.buscarAhora(texto)` (ya está en `onSubmitted`) |
| Borrar el texto ("x") | Ya está en `_borrarBusqueda` de `feed_page.dart`; reutilízalo |
| Chip de categoría / "Todo" | `cubit.elegirCategoria(categoria.id)` / `cubit.elegirCategoria(null)` |
| Chip "Mi carrera" | `cubit.alternarMiCarrera()`; para pintarlo activo usa `cubit.miCarreraActiva` |
| Abrir la hoja de filtros | `mostrarHojaFiltros(context)` |
| "Aplicar" / "Quitar" en la hoja | Ya están en `_aplicar` de `hoja_filtros.dart`; reutilízalos |
| Quitar el chip de división/carrera | `cubit.aplicarDivisionYCarrera()` |
| "Limpiar filtros" | Ya está en `_limpiarFiltros` de `feed_page.dart` (también borra el buscador); reutilízalo |
| Reintentar | `cubit.cargar()` |

---

## 5. Qué archivos puedes modificar

✅ **Sí:**

- `features/feed/presentation/pages/feed_page.dart`
- `features/feed/presentation/widgets/` (incluida `hoja_filtros.dart`; puedes sacar `_Buscador`, `_Chip` o `_BotonFiltros` a su propio archivo aquí)
- `features/publicaciones/presentation/widgets/` (tarjeta y etiquetas)
- `core/theme/app_theme.dart` y `core/widgets/aviso_pantalla.dart`
- `assets/` si necesitas la ilustración de "sin resultados" (avísanos para registrarla en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `presentation/cubit/` de cualquier feature (incluidos `feed_cubit.dart`, `feed_state.dart` y `opciones_filtro.dart`)
- `features/feed/presentation/feed_keys.dart` y las demás Keys
- `domain/` y `data/` de cualquier feature
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 6. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo. Así las pruebas siguen funcionando aunque cambie el diseño. Las Keys de HU-04 (`lista`, `cargando`, `vacio`, `error`, `cargandoMas`, `finDeLista`…) siguen igual.

| Key (`FeedKeys`) | Widget |
| :--- | :--- |
| `buscador` | Campo de texto del buscador (antes era un botón; ahora es un `TextField`) |
| `borrarBusquedaBoton` | La "x" del buscador |
| `filtrosBoton` | Botón que abre la hoja de filtros |
| `miCarreraChip` | Chip "Mi carrera" |
| `filtroAcademicoChip` | Chip de la división o carrera elegida (con "x") |
| `filtro('Todo')`, `filtro('Calculadoras')`… | Cada chip de categoría, por su nombre |
| `limpiarFiltrosBoton` | "Limpiar filtros" junto al título |
| `hojaFiltros` | La hoja de filtros |
| `divisionFiltro` / `carreraFiltro` | Selectores de la hoja |
| `aplicarFiltrosBoton` / `quitarFiltrosAcademicosBoton` | Botones de la hoja |
| `reintentarOpcionesBoton` | "Reintentar" de la hoja cuando no cargó el catálogo |
| `sinResultados` / `limpiarFiltrosSinResultadosBoton` | Pantalla "sin resultados" y su botón |

---

## 7. Cómo probarlo

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

- **Mi carrera:** entra con tu cuenta; el chip debe aparecer activo. Si nadie de tu carrera ha publicado, verás "sin resultados".
- **Buscar:** escribe "calcu" o "CIENTIFICA" (sin acentos); deben salir las calculadoras científicas.
- **Sin resultados:** busca "Calculadora Científica HP".
- **Hoja de filtros:** elige una división; la lista de carreras cambia.
- **Sin conexión:** `F12` → *Network* → *Offline* y cambia un filtro o presiona "Reintentar".

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-05-busqueda-filtros`; usa commits `style(feed): ...` y adjunta capturas en el PR del Feed con "Mi carrera", con una búsqueda, de "sin resultados" y de la hoja de filtros.
