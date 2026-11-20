# Guía de diseño - HU-09 Reputación de 1 a 5 estrellas (Sprint 9)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

La reputación ya funciona (issue #38) y usa la paleta del logo y los widgets compartidos (`PrimaryButton`, `AppTextField`, `mostrarMensaje`). Tu trabajo es diseñarla en Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Las pantallas

| Pantalla o pieza | Archivo | Cuándo aparece |
| :--- | :--- | :--- |
| Hoja "¿A quién se lo vendiste?" | `features/reputacion/presentation/widgets/hoja_elegir_comprador.dart` | Al tocar "Marcar como Vendido" en "Gestionar publicación". **Reemplaza** el cuadro "¿Marcar como Vendido?" de HU-06. |
| Hoja "Calificar" | `features/reputacion/presentation/widgets/hoja_calificar.dart` (`HojaCalificar`) | Al tocar "Calificar" en el aviso del chat o de Mi perfil. Se abre desde abajo. |
| Aviso "Califica tu trato con …" | El mismo archivo (`AvisoCalificarTrato`) | En el chat (debajo del encabezado) y en Mi perfil, durante los 14 días después de la venta, mientras no califiques. |
| Estrellas y etiqueta de reputación | `features/reputacion/presentation/widgets/estrellas.dart` (`Estrellas`, `SelectorEstrellas`, `EtiquetaReputacion`, `ReputacionDe`) | En el Detalle (debajo del nombre del vendedor) y en el encabezado del chat (debajo del nombre del otro). |
| Sección "Mi reputación" | `features/reputacion/presentation/widgets/seccion_reputacion.dart` | En Mi perfil, debajo de la tarjeta del perfil y antes de "Mis publicaciones". |

Todas las rutas de archivo son relativas a `app/lib/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

**Hoja "¿A quién se lo vendiste?", de arriba hacia abajo:** título → texto "Elige con quién hiciste el trato…" → una opción por cada estudiante que te escribió por esa publicación (foto, nombre y "Último mensaje: …") → opción **"Lo vendí fuera de UTrueque"** (siempre está, aunque falle la carga) → aviso "Ya no podrás cambiar su estado ni editarla." → "Sí, marcar como Vendido" (se habilita al elegir) → "Cancelar". La opción elegida lleva borde azul y palomita.

**Hoja "Calificar":** foto y nombre del otro → "Te vendió / Te compró …" → **5 estrellas grandes** con el texto debajo (Malo, Regular, Bueno, Muy bueno, Excelente) → campo "Comentario (opcional)" con contador "12/200" → caja roja con el error, si hay → "Enviar calificación" → nota "Tu calificación no se puede cambiar después…".

**Mi reputación:** el promedio grande ("4.3"), las estrellas y "2 calificaciones"; si tiene menos de 5, la nota del promedio ajustado; y 5 barras (de 5 a 1 estrellas) con cuántas tiene de cada una. Debajo, los avisos "Califica tu trato" y la lista **"Calificaciones que recibí"** (foto, nombre, fecha, estrellas, "Le vendiste/Le compraste …" y el comentario) con "Ver más".

**Sin calificaciones:** se muestra **"Nuevo en UTrueque · Sin calificaciones aún"**, sin estrellas ni "0.0" (Escenario 7). Diseña este caso también.

Colores nuevos en `core/theme/app_theme.dart`: `AppColores.estrella` (amarillo de las estrellas) y `AppColores.estrellaSuave` (fondo del aviso). Si los cambias, cámbialos **ahí**.

---

## 2. Estados de los Cubits

### Hoja "¿A quién se lo vendiste?" (`ElegirCompradorCubit`)

| Dato | Qué mostrar |
| :--- | :--- |
| `cargando` | Indicador de carga |
| `error` | El mensaje y "Reintentar". "Lo vendí fuera de UTrueque" sigue disponible |
| `compradores` | Las opciones. Si está vacía: "Nadie te ha escrito por esta publicación…" |
| `eleccion` | Lo elegido (`eleccion.fueraDeUTrueque` si fue fuera) |
| `completa` | Habilita "Sí, marcar como Vendido" |

### Hoja "Calificar" (`CalificarCubit`)

| Dato | Qué mostrar |
| :--- | :--- |
| `estrellas` | Cuántas estrellas pintar (`null` = ninguna) |
| `comentario`, `largoComentario` | El texto y el contador |
| `errorComentario` | Error debajo del campo (más de 200 caracteres o caracteres no permitidos) |
| `completa` | Habilita "Enviar calificación" |
| `enviando` | Spinner en el botón; estrellas y campo deshabilitados |
| `error` | Por qué no se envió. **Las estrellas y el comentario se conservan** |
| `enviada` / `tratoCerrado` | La hoja ya se cierra sola y muestra el mensaje; no hay que hacer nada |

### Reputación (`ReputacionCubit`)

Tres estados: `ReputacionCargando`, `ReputacionLista` (con `reputacion`) y `ReputacionError` (con `mensaje`). De `reputacion` usa: `texto` ("4.3 · 2 calificaciones" o el de sin calificaciones), `promedioTexto`, `totalTexto`, `estrellasLlenas`, `ajustada`, `sinCalificaciones` y `resumen.de(n)` para las barras. En el Detalle y el chat, si falla la carga no se muestra nada (no estorba).

### Avisos y lista (`TratosPorCalificarCubit`, `CalificacionesRecibidasCubit`)

`tratos` (cada aviso usa `trato.invitacion` y los días que quedan) y `calificaciones`, `hayMas`, `cargandoMas`, `error`, `errorMas`.

Los textos **ya vienen en español** desde la lógica. No escribas los tuyos. **El número del promedio no lo calcules en la pantalla:** usa `reputacion.promedioTexto` (lo calcula el patrón Strategy).

---

## 3. Qué método llama cada acción

| Acción | Llamada |
| :--- | :--- |
| Abrir "¿A quién se lo vendiste?" | Ya está en `_escuchar` de `hoja_gestionar_publicacion.dart` (`elegirComprador(...)`); reutilízalo |
| Elegir a alguien / fuera de UTrueque | `cubit.elegir(comprador)` / `cubit.elegirFueraDeUTrueque()` |
| "Sí, marcar como Vendido" | `Navigator.of(context).pop(eleccion)` (ya está) |
| Reintentar la lista | `cubit.cargar()` |
| Abrir "Calificar" | `HojaCalificar.abrir(context, trato)` (ya está en `ChatPage._calificar` y en la sección de Mi perfil) |
| Tocar una estrella | `cubit.elegirEstrellas(n)` |
| Escribir el comentario | `cubit.cambiarComentario(texto)` |
| "Enviar calificación" | `cubit.enviar()` |
| "Ver más" | `cubit.cargarMas()` |

---

## 4. Qué archivos puedes modificar

✅ **Sí:**

- `features/reputacion/presentation/widgets/` (solo lo visual)
- `features/perfil/presentation/pages/mi_perfil_page.dart`, `features/publicaciones/presentation/pages/detalle_publicacion_page.dart` y `features/chat/presentation/pages/chat_page.dart` (solo lo visual)
- `core/theme/app_theme.dart`
- `assets/` si necesitas íconos o ilustraciones (avísanos para registrarlos en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `features/reputacion/presentation/cubit/` y `reputacion_keys.dart`
- Calcular el promedio o redondear en la pantalla (lo hace `domain/strategies/estrategias_reputacion.dart`)
- Dejar editar o borrar una calificación, o quitar el límite de 200 caracteres (reglas de la decisión 3 y 4)
- `domain/` y `data/` de cualquier feature
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 5. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo (`ReputacionKeys`).

**Hoja "¿A quién se lo vendiste?":** `hojaComprador`, `compradoresCargando`, `compradoresError`, `compradoresReintentar`, `compradoresVacio`, `comprador(conversacionId)` en cada opción, `fueraDeUTrueque`, `confirmarVenta` y `cancelarVenta`.

**Hoja "Calificar":** `hojaCalificar`, `estrella(n)` en cada estrella (1 a 5), `comentario`, `contador`, `mensajeError` y `enviarCalificacion`.

**Avisos:** `avisoCalificar(ventaId)` y `calificarBoton(ventaId)`.

**Etiqueta:** `etiqueta` y `sinCalificaciones`.

**Mi reputación:** `seccion`, `promedio`, `avisoAjustado`, `barra(n)`, `resumenError`, `resumenReintentar`, `recibidas`, `recibida(id)`, `recibidasVacio`, `recibidasError` y `verMas`.

Las Keys de HU-06 (`GestionarKeys`), del chat (`ChatKeys`) y del punto de encuentro (`EncuentroKeys`) siguen igual.

---

## 6. Cómo probarlo

Se necesitan **dos cuentas** con una conversación entre ellas (dos celulares, o un celular y Chrome) y la migración de HU-09 aplicada en Supabase:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

(o el botón **Run** de VS Code, que ya carga `env.json`).

- **Vender:** con la cuenta A (vendedor), en "Mis publicaciones" → "Gestionar" → "Marcar como Vendido" → elige a B → "Sí, marcar como Vendido". Sale "Listo. Ya pueden calificarse."
- **Calificar como comprador:** con B, abre el chat de esa publicación: arriba aparece "Califica tu trato con A". Toca "Calificar", 5 estrellas, un comentario y "Enviar calificación". El aviso desaparece.
- **Calificar como vendedor:** con A, en Mi perfil aparece el aviso para calificar a B.
- **Ver la reputación:** en Mi perfil de A, el promedio, las barras y el comentario de B. En el Detalle de otra publicación de A y en el chat, la etiqueta con estrellas.
- **Sin calificaciones:** con una cuenta nueva, "Nuevo en UTrueque · Sin calificaciones aún".
- **Comentario no válido:** escribe más de 200 caracteres: el contador se pone rojo y el botón se deshabilita.
- **Fuera de UTrueque:** vende otra publicación eligiendo "Lo vendí fuera de UTrueque": no aparece ningún aviso.
- **Sin conexión:** `F12` → *Network* → *Offline* y toca "Enviar calificación": sale el mensaje y se conservan las estrellas.

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-09-reputacion`; usa commits `style(reputacion): ...` y adjunta en el PR capturas de las dos hojas (cargando, con opciones y con error), del aviso, de la etiqueta en el Detalle y el chat, y de "Mi reputación" con y sin calificaciones.
