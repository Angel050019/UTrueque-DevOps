# Guía de diseño - HU-03 Publicar artículo (Sprint 3)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

La pantalla "Publicar artículo" ya funciona y ya usa la paleta del logo y los widgets compartidos (`PrimaryButton`, `AppTextField`, `BarraSuperior`, `mostrarMensaje`). Tu trabajo es revisarla contra Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. La pantalla

| Pantalla | Archivo | Ruta | Cuándo aparece |
| :--- | :--- | :--- | :--- |
| Publicar artículo | `presentation/pages/publicar_articulo_page.dart` | `/publicar` | Desde el botón flotante "Publicar" del Feed. Al publicar con éxito regresa al Feed. |

Todas las rutas son relativas a `app/lib/features/publicaciones/`.

Orden de arriba hacia abajo: fotos → título → descripción → categoría → modalidad (Venta / Intercambio / Gratis) → precio (solo en Venta) → aviso "Tu artículo aparecerá como Disponible…" → botón fijo "Publicar artículo".

Piezas en `presentation/widgets/`:

| Widget | Para qué sirve |
| :--- | :--- |
| `SelectorFotos` | Tira horizontal: botón "Agregar" y miniaturas con "quitar". La primera foto lleva la etiqueta "Portada". |
| `SelectorCategoria` | Lista desplegable de categorías. |
| `SelectorModalidad` | Tres botones; el elegido va en azul `#033B56` con ícono menta. |
| `CargandoPublicacion` / `ErrorCargaPublicacion` | Carga del catálogo y error con botón "Reintentar". |
| `elegirFotosArticulo()` | Abre la galería. No la cambies; solo llámala. |

El botón "Publicar" del Feed y la lista "Publicaciones recientes" están en `features/feed/presentation/pages/feed_placeholder_page.dart`. Cada artículo de la lista se dibuja con `presentation/widgets/tarjeta_publicacion.dart` (portada, título, categoría · dueño, modalidad o precio y estado); también puedes ajustar su diseño, conservando `PublicacionKeys.tarjeta(id)` y las Keys `feedLista`, `feedVacio`, `feedCargando`, `feedError` y `feedReintentarBoton`.

---

## 2. Estados del Cubit

| Estado | Qué mostrar |
| :--- | :--- |
| `PublicacionInicial` / `PublicacionCargando` | Indicador de carga |
| `PublicacionEditando` | El formulario |
| `PublicacionEnviando` | El formulario con campos deshabilitados y el botón en modo "cargando" |
| `PublicacionPublicada` | Nada nuevo: la página muestra "¡Listo!…" y regresa sola al Feed |
| `PublicacionError` **con** `datos` | El formulario igual que antes **y** el mensaje (`state.mensaje`) |
| `PublicacionError` **sin** `datos` | Pantalla de error con "Reintentar" |

Los errores de cada campo vienen en `datos.errorDe(CampoPublicacion.titulo)` (y `.descripcion`, `.categoria`, `.modalidad`, `.precio`, `.fotos`). Si no es `null`, ese campo va en rojo con ese texto debajo. Los textos **ya vienen en español** desde la lógica; no escribas los tuyos.

---

## 3. Qué método llama cada acción

Obtén el Cubit con `context.read<PublicacionCubit>()`.

| Acción | Llamada |
| :--- | :--- |
| Agregar fotos | `final fotos = await elegirFotosArticulo(maximo: 5 - datos.fotos.length); cubit.agregarFotos(fotos);` |
| Quitar una foto | `cubit.quitarFoto(indice)` |
| Elegir categoría | `cubit.seleccionarCategoria(categoria)` |
| Elegir modalidad | `cubit.seleccionarModalidad(Modalidad.venta)` (o `intercambio`, `gratis`) |
| Escribir en un campo | `cubit.campoEditado(CampoPublicacion.titulo)` (quita el rojo de ese campo) |
| Publicar | `cubit.publicar(titulo: ..., descripcion: ..., precioTexto: ...)` con el texto de cada controller |
| Reintentar carga | `cubit.cargarCategorias()` |

---

## 4. Qué archivos puedes modificar

✅ **Sí:** `features/publicaciones/presentation/pages/`, `features/publicaciones/presentation/widgets/` (menos la lógica de `elegir_fotos_articulo.dart`), `core/theme/app_theme.dart` y el botón "Publicar" del Feed.

❌ **No** (pídelo al equipo de desarrollo): `presentation/cubit/`, `presentation/publicacion_keys.dart`, `domain/`, `data/`, `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `test/` y `supabase/`.

**Conserva las Keys** de `PublicacionKeys` (por ejemplo `tituloField`, `precioField`, `publicarBoton`, `modalidad(Modalidad.venta)`, `quitarFoto(0)`). Si cambias un widget por otro, pásale la misma Key.

---

## 5. Cómo probarla

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

Entra con una cuenta con perfil completo → botón "Publicar" del Feed. Para ver los errores: presiona "Publicar artículo" sin llenar nada, o elige Venta y deja el precio vacío.

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-03-publicar-articulo`; usa commits `style(publicaciones): ...` y adjunta capturas en el PR.
