# Guía de diseño - HU-06 Gestión de "Mis publicaciones" (Sprint 6)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

"Mis publicaciones", la hoja "Gestionar publicación" y "Editar publicación" ya funcionan y usan la paleta del logo y los widgets compartidos (`PrimaryButton`, `SecondaryButton`, `BarraSuperior`, `AvisoPantalla`, `mostrarMensaje`, `TarjetaPublicacion`, `EtiquetaPublicacion`). Tu trabajo es diseñarlas en Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Las pantallas

| Pantalla | Archivo | Ruta | Cuándo aparece |
| :--- | :--- | :--- | :--- |
| Mis publicaciones | `features/publicaciones/presentation/pages/mis_publicaciones_page.dart` | `/mis-publicaciones` | Desde "Mis publicaciones" en Mi perfil. |
| Hoja "Gestionar publicación" | `features/publicaciones/presentation/widgets/hoja_gestionar_publicacion.dart` | (hoja que sube desde abajo) | Desde "Gestionar" en Mis publicaciones o "Gestionar publicación" en el Detalle de una publicación mía. |
| Editar publicación | `features/publicaciones/presentation/pages/publicar_articulo_page.dart` (el mismo de "Publicar artículo") | `/publicacion/editar` | Desde "Editar publicación" en la hoja. |

Todas las rutas de archivo son relativas a `app/lib/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

**Ya no existen** los dos "En desarrollo" del Sprint 6 (Mis publicaciones en Mi perfil y Gestionar publicación en el Detalle).

**Mis publicaciones, de arriba hacia abajo:** barra con regreso → pestañas **Activas** / **Finalizadas** → lista de tarjetas. Debajo de cada tarjeta Activa va el botón "Gestionar"; las Finalizadas no lo tienen. Al tocar la tarjeta se abre su Detalle. Al final de la lista: spinner (cargando más) o error con "Reintentar".

**Hoja "Gestionar publicación":** título, nombre del artículo con su etiqueta de estado y los botones que **permite su estado** (patrón State):

| Estado | Botones |
| :--- | :--- |
| Disponible | "Marcar como Reservado" · "Marcar como Vendido" · "Editar publicación" · "Borrar publicación" (rojo) |
| Reservado | "Volver a Disponible" · "Marcar como Vendido" |
| Vendido | Ninguno: aviso "Esta publicación ya está finalizada…" |

"Marcar como Vendido" y "Borrar publicación" abren una **confirmación** (`AlertDialog`) con "Cancelar" y "Sí, …". Mientras se envía, aparece una barra de progreso y los botones se deshabilitan.

**Editar publicación:** el mismo formulario de "Publicar artículo" con los datos actuales. Cambia el título de la barra ("Editar publicación"), el botón ("Guardar cambios") y el aviso de abajo. Las fotos que ya estaban se ven desde internet; las nuevas, desde el celular.

---

## 2. Estados de los Cubits

### Mis publicaciones (`MisPublicacionesCubit`)

Todos los estados traen `state.finalizadas` (`false` = pestaña Activas, `true` = Finalizadas).

| Estado | Qué mostrar |
| :--- | :--- |
| `MisPublicacionesCargando` | Indicador de carga (también al cambiar de pestaña) |
| `MisPublicacionesCargado` | La lista. Al final: spinner si `cargandoMas`, el mensaje `errorMas` con "Reintentar" si no es `null` |
| `MisPublicacionesVacio` | `state.mensaje` ("Aún no tienes publicaciones activas." o "…finalizadas.") y, en Activas, el botón "Publicar artículo" |
| `MisPublicacionesError` | `state.mensaje` y "Reintentar". `state.sinConexion` te dice si es por falta de internet (para cambiar ícono o ilustración) |

Si `MisPublicacionesCargado.aviso` no es `null` (por ejemplo, al jalar para actualizar sin internet), la página ya muestra un SnackBar; la lista se conserva.

### Gestionar (`GestionarPublicacionCubit`)

| Estado | Qué mostrar |
| :--- | :--- |
| `GestionLista` | Los botones de `state.operaciones` y "Editar publicación" si `state.sePuedeEditar` |
| `GestionConfirmando` | La confirmación con `operacion.tituloConfirmacion`, `operacion.textoConfirmacion` y `operacion.botonConfirmacion` |
| `GestionEnviando` | Barra de progreso; botones deshabilitados |
| `GestionTerminada` | Nada nuevo: la hoja muestra `state.mensaje` y se cierra sola |
| `GestionError` | La hoja muestra `state.mensaje` y regresa sola a la lista (con el estado actualizado si cambió) |

Los textos **ya vienen en español** desde la lógica (`state.mensaje`, `operacion.etiqueta`, `operacion.textoConfirmacion`). No escribas los tuyos.

---

## 3. Qué método llama cada acción

| Acción | Llamada |
| :--- | :--- |
| Cambiar de pestaña | `context.read<MisPublicacionesCubit>().cambiarPestana(finalizadas: true/false)` (ya está en `_Pestanas`) |
| Jalar para actualizar / Reintentar | `cubit.actualizar()` / `cubit.cargar()` |
| Cargar más / reintentar cargar más | `cubit.cargarMas()` (ya se llama solo al acercarse al final) |
| Abrir el Detalle desde una tarjeta | Ya está en `_abrirDetalle`; reutilízalo |
| Abrir la hoja "Gestionar" | `gestionarPublicacion(context, publicacion)` (ya está en `_MiPublicacion` y en `_Acciones` del Detalle) |
| Botón de una operación en la hoja | `context.read<GestionarPublicacionCubit>().elegir(operacion)` |
| "Editar publicación" en la hoja | Ya está (cierra la hoja y abre "Editar publicación"); reutilízalo |
| Confirmar / cancelar | Ya está en `_confirmar` de la hoja (llama a `confirmar()` o `cancelar()`); reutilízalo |
| "Guardar cambios" | El mismo `_publicar` de "Publicar artículo" |

---

## 4. Qué archivos puedes modificar

✅ **Sí:**

- `features/publicaciones/presentation/pages/mis_publicaciones_page.dart`
- `features/publicaciones/presentation/widgets/hoja_gestionar_publicacion.dart` (solo lo visual de `_HojaGestionar` y del diálogo de confirmación)
- `features/publicaciones/presentation/pages/publicar_articulo_page.dart` y `detalle_publicacion_page.dart` (solo lo visual)
- `features/publicaciones/presentation/widgets/` (tarjeta, etiquetas y `selector_fotos.dart`; menos la lógica de `elegir_fotos_articulo.dart`)
- `features/perfil/presentation/pages/mi_perfil_page.dart` (el acceso a "Mis publicaciones")
- `core/theme/app_theme.dart` y `core/widgets/aviso_pantalla.dart`
- `assets/` si necesitas ilustraciones (avísanos para registrarlas en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `presentation/cubit/` de cualquier feature (incluidos `mis_publicaciones_cubit.dart`, `gestionar_publicacion_cubit.dart` y sus estados)
- `presentation/avisos_publicaciones.dart` (avisa al Feed de los cambios)
- La función `gestionarPublicacion(...)` de la hoja y la clase `_Salida`
- `mis_publicaciones_keys.dart` y las demás Keys
- `domain/` y `data/` de cualquier feature
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 5. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo. Así las pruebas siguen funcionando aunque cambie el diseño.

**Mis publicaciones (`MisPublicacionesKeys`):**

| Key | Widget |
| :--- | :--- |
| `pantalla` | El `Scaffold` |
| `activasTab` / `finalizadasTab` | Las dos pestañas |
| `lista` | La lista de publicaciones |
| `cargando` | Indicador de la primera carga |
| `vacio` / `publicarBoton` | Pantalla vacía y su botón "Publicar artículo" |
| `error` / `reintentarBoton` | Pantalla de error y su botón |
| `cargandoMas` / `finDeLista` | Spinner y fin de la lista |
| `errorMas` / `reintentarMasBoton` | Error al cargar más y su botón |
| `gestionar(id)` | Botón "Gestionar" de cada publicación |
| `PublicacionKeys.tarjeta(id)` | Cada tarjeta (está en `publicacion_keys.dart`) |

**Hoja "Gestionar publicación" (`GestionarKeys`, en el mismo archivo):**

| Key | Widget |
| :--- | :--- |
| `hoja` | El contenido de la hoja |
| `estado` | Etiqueta de estado |
| `operacion(OperacionGestion.reservar)`, `…liberar`, `…marcarVendido`, `…borrar` | Botón de cada operación |
| `editarBoton` | "Editar publicación" |
| `finalizadaAviso` | Aviso de publicación finalizada |
| `enviando` | Barra de progreso |
| `confirmacion` / `confirmarBoton` / `cancelarBoton` | El diálogo y sus botones |

**Editar publicación:** usa las mismas Keys de `PublicacionKeys` que "Publicar artículo" (`tituloField`, `precioField`, `publicarBoton` para "Guardar cambios", `quitarFoto(0)`, …). **Detalle:** `DetalleKeys.gestionarBoton` sigue igual.

---

## 6. Cómo probarlo

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

(o el botón **Run** de VS Code, que ya carga `env.json`).

- **Mis publicaciones:** Mi perfil → "Mis publicaciones". Si no has publicado nada, verás la pantalla vacía.
- **Reservar / Volver a Disponible:** "Gestionar" en una publicación Disponible. Regresa al Feed: la tarjeta dice "Reservado".
- **Vender:** "Marcar como Vendido" → confirma → la publicación pasa a la pestaña Finalizadas y sale del Feed.
- **Editar:** "Gestionar" → "Editar publicación". Quita una foto, agrega otra y cambia el precio.
- **Borrar:** "Gestionar" → "Borrar publicación" → confirma.
- **Sin conexión:** `F12` → *Network* → *Offline* y cambia de pestaña o intenta reservar.

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-06-mis-publicaciones`; usa commits `style(publicaciones): ...` y adjunta en el PR capturas de Mis publicaciones (Activas, Finalizadas y vacía), de la hoja en los tres estados, de la confirmación de vender y de "Editar publicación".
