# Guía de diseño - HU-02 Perfil Académico (Sprint 2)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

La lógica de HU-02 ya está hecha y probada. Las pantallas funcionan, pero están "en blanco y negro": solo usan widgets básicos de Material. Tu trabajo es darles el diseño final **sin tocar la lógica**. Esta guía te dice qué hay, qué puedes cambiar y cómo conectar cada botón.

---

## 1. Las pantallas

| Pantalla | Archivo | Ruta | Cuándo aparece | Qué hace |
| :--- | :--- | :--- | :--- | :--- |
| Completar perfil | `presentation/pages/completar_perfil_page.dart` | `/perfil/completar` | Justo después del login, si el perfil está incompleto | Pide nombre, división, carrera y foto opcional. Al guardar lleva al Feed. No tiene botón "atrás". |
| Mi perfil | `presentation/pages/mi_perfil_page.dart` | `/perfil` | Desde el ícono de persona en el Feed | Muestra foto, nombre, división y carrera. Botones "Editar perfil" y "Cerrar sesión". |
| Editar perfil | `presentation/pages/editar_perfil_page.dart` | `/perfil/editar` | Desde "Editar perfil" en Mi perfil | Mismo formulario que Completar, con los datos actuales. Al guardar regresa a Mi perfil y esta se recarga. |

Todas las rutas son relativas a `app/lib/features/perfil/`.

Piezas reutilizables en `presentation/widgets/`:

| Widget | Para qué sirve |
| :--- | :--- |
| `AvatarPerfil` | Foto circular: muestra la foto recién elegida, la guardada o un ícono. |
| `SelectorAcademico` | Los dos selectores encadenados División → Carrera. |
| `FormularioPerfil` | Formulario completo (avatar + nombre + selectores + botón). Lo comparten Completar y Editar. |
| `TarjetaPerfil` | Datos del perfil en modo lectura (Mi perfil). |
| `CargandoPerfil` / `ErrorCargaPerfil` | Estado de carga y estado de error con botón "Reintentar". |
| `elegirFotoDeGaleria()` | Función que abre la galería y regresa la foto. No la cambies; solo llámala. |

Cada lugar que espera tu diseño tiene un comentario `// TODO(diseño): ...`. Búscalos en VS Code con `Ctrl+Shift+F` → `TODO(diseño)`.

---

## 2. Estados del Cubit que debes contemplar

Las pantallas escuchan al `PerfilCubit`. Cada estado dice qué dibujar:

| Estado | Qué significa | Qué debe mostrar la pantalla |
| :--- | :--- | :--- |
| `PerfilInicial` | Aún no empieza la carga | Lo mismo que Cargando |
| `PerfilCargando` | Se está leyendo el perfil y el catálogo | Indicador de carga |
| `PerfilCargado` | Todo listo | El formulario o la tarjeta |
| `PerfilGuardando` | Se está subiendo la foto y guardando | El formulario con el botón en modo "cargando" y los campos deshabilitados |
| `PerfilGuardado` | Se guardó con éxito | Nada nuevo: la página navega sola (al Feed o de regreso a Mi perfil) |
| `PerfilError` **con** `datos` | Falló al guardar o la foto no es válida | El formulario igual que antes **y** un mensaje (hoy es un SnackBar) con `state.mensaje` |
| `PerfilError` **sin** `datos` | Falló la carga inicial (por ejemplo, sin internet) | Pantalla de error con botón "Reintentar" |

Cómo leerlos dentro de un `BlocBuilder` o `BlocConsumer`:

```dart
builder: (context, state) {
  final PerfilDatos? datos = state.datos;   // null en Cargando o error de carga
  if (datos == null) {
    if (state is PerfilError) return ErrorCargaPerfil(mensaje: state.mensaje, onReintentar: ...);
    return const CargandoPerfil();
  }
  final bool guardando = state is PerfilGuardando;
  // Dibuja con: datos.perfil, datos.catalogo, datos.divisionSeleccionada,
  // datos.carreraSeleccionada, datos.carrerasDisponibles, datos.fotoNueva
}
```

Los mensajes de error **ya vienen en español** desde la lógica (`state.mensaje`). No escribas tus propios textos de error.

---

## 3. Qué método del Cubit llama cada botón

Obtén el Cubit con `context.read<PerfilCubit>()`.

| Acción del usuario | Llamada |
| :--- | :--- |
| Elegir foto | `final foto = await elegirFotoDeGaleria(); if (foto != null) cubit.seleccionarFoto(foto);` |
| Quitar la foto recién elegida | `cubit.quitarFotoNueva()` |
| Elegir división | `cubit.seleccionarDivision(division)` (si la carrera ya no corresponde, se limpia sola) |
| Elegir carrera | `cubit.seleccionarCarrera(carrera)` (usa solo las de `datos.carrerasDisponibles`) |
| Guardar (Completar y Editar) | `cubit.guardar(nombre: nombreController.text)` |
| Reintentar carga (Completar / Editar) | `cubit.cargarMiPerfil()` |
| Reintentar carga (Mi perfil) | `cubit.cargarMiPerfil(conCatalogo: false)` |
| Cerrar el mensaje de error | `cubit.descartarError()` (opcional) |
| Cerrar sesión (Mi perfil) | `context.read<AuthCubit>().cerrarSesion()` |
| Ir a editar (Mi perfil) | Ya está en `_irAEditar` de `mi_perfil_page.dart`; reutilízalo |

El texto del nombre vive en un `TextEditingController` de la página; eso sí es de la parte visual. Las validaciones (3 a 50 caracteres, carrera dentro de la división, foto JPG/PNG de máx. 5 MB) **no** se hacen en la pantalla: las hace el Cubit.

---

## 4. Qué archivos puedes modificar

✅ **Sí puedes modificar:**

- `app/lib/features/perfil/presentation/pages/` (las 3 pantallas)
- `app/lib/features/perfil/presentation/widgets/` (menos la lógica de `elegir_foto.dart`)
- `app/lib/core/theme/app_theme.dart` (colores y tema de toda la app: aquí va la paleta)
- `app/assets/` si necesitas imágenes (avísanos para registrarlas en `pubspec.yaml`)

❌ **No modifiques** (si necesitas algo de aquí, pídelo al equipo de desarrollo):

- `presentation/cubit/` (estados y Cubit)
- `presentation/perfil_keys.dart` (las Keys)
- `domain/` y `data/` de cualquier feature
- `lib/main.dart`, `core/routes/`, `core/errors/`, `core/constants/`
- `test/` y `supabase/`

**Muy importante: conserva las Keys.** Cada widget importante tiene una Key de `PerfilKeys` (por ejemplo `PerfilKeys.nombreField`, `PerfilKeys.guardarBoton`, `PerfilKeys.divisionSelector`). Si cambias un widget por otro, pásale la misma Key al nuevo. Así las pruebas siguen funcionando aunque cambie el diseño.

---

## 5. Cómo correr la app

Desde Git Bash, en la carpeta del repo:

```bash
cd app
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU-ANON-KEY
```

Pide la URL y la llave a Jose Luis; **nunca las escribas en el código ni las subas al repo**.

Para ver "Completar perfil" necesitas un usuario con el perfil incompleto (cualquier cuenta nueva). Mientras diseñas, usa `r` (hot reload) en la terminal para ver los cambios al instante.

Antes de subir cambios, corre siempre:

```bash
flutter analyze
flutter test
```

Las dos deben terminar sin errores.

---

## 6. Tu rama y tu Pull Request

1. Actualiza `develop` y crea tu rama **después** de que se fusione `feature/HU-02-perfil-academico`:

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/HU-02-perfil-ui
   ```

2. Trabaja y haz commits pequeños con Conventional Commits, por ejemplo:

   ```bash
   git add app/lib/features/perfil/presentation app/lib/core/theme
   git commit -m "style(perfil): diseño de la pantalla Completar perfil"
   ```

   Usa `style` para cambios visuales y `feat` si agregas un componente nuevo.

3. Sube tu rama:

   ```bash
   git push -u origin feature/HU-02-perfil-ui
   ```

4. En GitHub abre el Pull Request **hacia `develop`** (no hacia `main`), llena la plantilla y **adjunta capturas** de las 3 pantallas.
5. Espera al menos 1 aprobación y el CI en verde, y se fusiona con **Squash and Merge**.

Si `develop` avanzó mientras trabajabas: `git pull origin develop` en tu rama, resuelve conflictos si los hay, corre `flutter test` y vuelve a subir.
