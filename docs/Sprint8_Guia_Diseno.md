# Guía de diseño - HU-08 Punto de encuentro seguro (Sprint 8)

Para: **Diaz Huerta Diego Oziel**
De: Equipo de Desarrollo

El punto de encuentro ya funciona dentro del chat (issue #3) y usa la paleta del logo y los widgets compartidos (`PrimaryButton`, `SecondaryButton`, `mostrarMensaje`). Tu trabajo es diseñarlo en Figma y ajustar lo visual **sin tocar la lógica**.

---

## 1. Las pantallas

| Pantalla o pieza | Archivo | Cuándo aparece |
| :--- | :--- | :--- |
| Botón "Proponer punto de encuentro" (ícono de lugar) | `features/chat/presentation/pages/chat_page.dart` (`_CampoMensaje`) | A la izquierda del campo de texto del chat. Deshabilitado si ya hay un encuentro pendiente o confirmado, o si la publicación se vendió. |
| Hoja "Proponer punto de encuentro" | `features/encuentros/presentation/widgets/hoja_proponer_encuentro.dart` | Al tocar el botón. Se abre desde abajo. |
| Tarjetas de encuentro | `features/encuentros/presentation/widgets/tarjeta_encuentro.dart` (`TarjetaEncuentro`) | Dentro de la lista de mensajes, centradas, cada vez que alguien propone, acepta, rechaza o cancela. |
| Aviso fijo del encuentro confirmado | El mismo archivo (`AvisoEncuentroConfirmado`) | Arriba del chat, debajo del encabezado, mientras haya un encuentro confirmado y su hora no haya pasado. |

Todas las rutas de archivo son relativas a `app/lib/`. Busca `TODO(diseño)` en VS Code (`Ctrl+Shift+F`) para ver los lugares marcados.

**Hoja, de arriba hacia abajo:** título y explicación del horario → **Lugar** (una opción por cada lugar del catálogo, con su nombre y su referencia) → **Día** (botones deslizables: "mié 11", "jue 12"… solo de lunes a viernes) → **Hora** (botones de 7:00 a 20:00 cada media hora; solo los que todavía se pueden elegir) → mensaje de error, si hay → "Enviar propuesta". **No hay ningún campo para escribir**: así no se pueden proponer lugares fuera del campus.

**Tarjetas (hay cuatro clases):**

| Tarjeta | Título | Qué muestra | Botones |
| :--- | :--- | :--- | :--- |
| Propuesta | "Propuesta de encuentro" | Lugar, referencia, día y hora, y el estado: "Te toca responder", "Esperando respuesta", "Confirmado", "Rechazada", "Cancelada" o "Venció" | Al otro: "Aceptar punto de encuentro" y "Rechazar". A quien propuso: "Cancelar propuesta". Solo mientras está pendiente |
| Confirmación | "Punto de encuentro confirmado" | En verde menta (`acentoSuave`). Lugar, día y hora. Si luego se cancela o ya pasó, lo dice abajo | "Cancelar encuentro" (a los dos), mientras siga confirmado |
| Rechazo | "Propuesta rechazada" | Lugar y "La rechazaste." o "La rechazó el otro estudiante." | Ninguno |
| Cancelación | "Encuentro cancelado" | Lugar y "Lo cancelaste." o "Lo canceló el otro estudiante." | Ninguno |

Antes de cancelar sale un cuadro de confirmación ("¿Cancelar el encuentro?").

---

## 2. Estados de los Cubits

### Encuentros del chat (`EncuentrosCubit`)

Es **un solo estado** (`EncuentrosState`) con estos datos:

| Dato | Qué significa |
| :--- | :--- |
| `encuentros` | Los encuentros de la conversación. Cada tarjeta busca el suyo con `state.porId(mensaje.encuentroId)`. Si todavía no llega (`null`), la tarjeta muestra el texto del mensaje |
| `confirmadoAl(ahora)` | El encuentro confirmado para el aviso fijo, o `null` |
| `activoAl(ahora)` | El encuentro pendiente o confirmado, o `null` |
| `enviando` | Se está aceptando, rechazando o cancelando: los botones de las tarjetas se deshabilitan |
| `aviso` / `avisoEsError` | Mensaje de un solo uso. La página ya lo muestra en un SnackBar ("Punto de encuentro confirmado.", o el motivo del error) |

Y del Cubit: `cubit.puedeProponer` (habilita el botón de lugar) y `cubit.cerrada` (publicación Vendida o borrada: sin botones).

### Hoja (`PropuestaEncuentroCubit`)

| Dato | Qué mostrar |
| :--- | :--- |
| `cargando` | Indicador de carga |
| `errorCatalogo` | El mensaje y "Reintentar" (por ejemplo, sin conexión) |
| `puntos`, `dias`, `horas` | Las opciones. Ya vienen filtradas: solo lugares del catálogo y horarios permitidos |
| `punto`, `dia`, `hora` | Lo elegido |
| `completa` | Habilita "Enviar propuesta" |
| `enviando` | Spinner en "Enviar propuesta" |
| `error` | Por qué no se envió. **Lo elegido se conserva** |

Los textos **ya vienen en español** desde la lógica. No escribas los tuyos. Para fechas y horas usa `HorarioEncuentro.formatear(...)`, `formatearDiaCorto(...)` y `formatearHora(...)`: usan la hora de la universidad, no la del celular.

---

## 3. Qué método llama cada acción

| Acción | Llamada |
| :--- | :--- |
| Abrir la hoja | Ya está en `_proponer` de `ChatPage` (`HojaProponerEncuentro.abrir(...)`); reutilízalo |
| Elegir lugar / día / hora | `cubit.elegirPunto(p)` / `cubit.elegirDia(d)` / `cubit.elegirHora(h)` |
| "Enviar propuesta" | Ya está en `_enviar` de la hoja: llama a `cubit.enviar()` y, si regresa `true`, cierra la hoja |
| Reintentar el catálogo | `cubit.cargar()` |
| "Aceptar punto de encuentro" / "Rechazar" | `_aceptar(encuentro)` / `_rechazar(encuentro)` de `ChatPage` (llaman a `EncuentrosCubit.responder`) |
| "Cancelar propuesta" / "Cancelar encuentro" | `_cancelar(encuentro)` de `ChatPage` (pide confirmación y llama a `EncuentrosCubit.cancelar`) |

---

## 4. Qué archivos puedes modificar

✅ **Sí:**

- `features/encuentros/presentation/widgets/` (`hoja_proponer_encuentro.dart` y `tarjeta_encuentro.dart`, solo lo visual)
- `features/chat/presentation/pages/chat_page.dart` (solo lo visual, incluido el botón de lugar)
- `core/theme/app_theme.dart`
- `assets/` si necesitas íconos o ilustraciones (avísanos para registrarlos en `pubspec.yaml`)

❌ **No** (pídelo al equipo de desarrollo):

- `features/encuentros/presentation/cubit/` y `features/chat/presentation/cubit/`
- `encuentro_keys.dart`, `chat_keys.dart` y las demás Keys
- Agregar un campo para escribir el lugar o una nota: es una regla de seguridad (Escenario 5)
- `domain/` y `data/` de cualquier feature (ahí están el catálogo, el horario y el patrón Factory Method)
- `main.dart`, `core/routes/`, `core/errors/`, `core/constants/`, `core/utils/`
- `test/` y `supabase/`

---

## 5. Keys que debes conservar

Si cambias un widget por otro, **pásale la misma Key** al nuevo.

**En el chat (`EncuentroKeys`):** `botonProponer` y `avisoConfirmado`.

**Hoja:** `hoja`, `hojaCargando`, `hojaError`, `hojaReintentar`, `hojaSinHorarios`, `hojaMensajeError`, `enviarPropuesta`, `punto(id)` en cada lugar, `dia(dia)` en cada día y `hora(hora)` en cada horario.

**Tarjetas:** `tarjeta(mensajeId)`, `estadoTarjeta(mensajeId)`, `aceptar(mensajeId)`, `rechazar(mensajeId)`, `cancelar(mensajeId)` y `confirmarCancelar` en el "Sí, cancelar" del cuadro.

Las Keys del chat de HU-07 (`ChatKeys`, `BandejaKeys`) siguen igual.

---

## 6. Cómo probarlo

Se necesitan **dos cuentas** con una conversación entre ellas (dos celulares, o un celular y Chrome) y la migración de HU-08 aplicada en Supabase:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=env.json
```

(o el botón **Run** de VS Code, que ya carga `env.json`).

- **Proponer:** con la cuenta A, en el chat toca el ícono de lugar, elige "Biblioteca - Entrada Principal", un día y una hora, y "Enviar propuesta". En la cuenta B aparece la tarjeta sin refrescar.
- **Aceptar:** con B, "Aceptar punto de encuentro". En los dos aparece la tarjeta verde y el aviso fijo arriba.
- **Un solo encuentro:** con un encuentro confirmado, el ícono de lugar queda deshabilitado.
- **Cancelar:** con cualquiera, "Cancelar encuentro" → "Sí, cancelar". Desaparece el aviso fijo y se puede proponer otro.
- **Rechazar:** propón otra vez con A y rechaza con B.
- **Solo lectura:** con el vendedor, marca la publicación como Vendida; las tarjetas se ven sin botones y no hay ícono de lugar.
- **Sin conexión:** `F12` → *Network* → *Offline*, abre la hoja y verás el error con "Reintentar".

Antes de subir cambios: `flutter analyze` y `flutter test` sin errores. Tu rama sale de `develop` **después** de que se fusione `feature/HU-08-punto-encuentro`; usa commits `style(encuentros): ...` y adjunta en el PR capturas de la hoja (cargando, con opciones y con error), de las cuatro tarjetas y del aviso fijo.
