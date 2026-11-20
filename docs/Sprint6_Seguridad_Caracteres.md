# Seguridad: caracteres permitidos (Sprint 6)

Observación de la docente: el título de las publicaciones aceptaba cualquier carácter especial. Se revisaron todos los campos de texto de la app y se aplicó **validación de entrada con lista de permitidos**: en cada campo solo se aceptan los caracteres que hacen falta y se rechaza todo lo demás, en lugar de intentar adivinar qué símbolos son peligrosos.

Rama: `feature/validacion-caracteres` · Migración: `supabase/migrations/20261030120000_validacion_caracteres.sql`

## 1. Qué acepta cada campo

| Campo | Qué se permite | Se rechaza, por ejemplo |
| :--- | :--- | :--- |
| Título de la publicación | Letras (con acentos, ñ y ü), números, espacios y `. , - ( ) / # + : % ° $ ¿ ? ¡ !` | `< > { } [ ] \ \| ` ~ ^ = * & @ _ ; ' "`, emojis, saltos de línea y caracteres invisibles |
| Descripción | Lo mismo que el título, más saltos de línea | Lo mismo que el título |
| Nombre a mostrar (perfil) | Letras (con acentos, ñ y ü), espacios, punto y guion | Números, comillas, `_`, `;`, `<`, emojis… |
| Buscador del Feed | Letras, números y espacios (máximo 100) | Cualquier signo |
| Precio | Números, punto, coma, espacio y `$` | Letras y otros signos |
| Correo institucional | Letras sin acentos, números y `. _ @ -` | Espacios, comillas, `ñ`, `;`… |
| **Contraseña** | **Sin límite** | — |

**¿Por qué la contraseña no se limita?** Los caracteres especiales hacen la contraseña más fuerte. Además, la contraseña nunca se guarda ni se muestra como texto: Supabase la guarda cifrada. Limitarla haría la app menos segura.

## 2. Dónde se aplica (defensa en profundidad)

1. **Al escribir:** cada campo tiene un filtro (`FiltrosTexto`) que no deja teclear ni pegar caracteres fuera de la lista.
2. **Antes de enviar:** los validadores (`PublicacionValidator`, `PerfilValidator`) revisan el texto completo y marcan el campo en rojo con un mensaje que dice qué signos sí se permiten.
3. **En la base de datos:** dos triggers (`publicaciones_validar_caracteres` y `usuarios_validar_caracteres`) aplican **exactamente la misma lista**, porque alguien podría saltarse la app y llamar al API directamente. Si rechazan algo, responden con el error 23514 y una pista fija (`titulo_caracteres`, `descripcion_caracteres`, `nombre_caracteres`), y la app marca el campo exacto sin mostrar detalles internos.

La lista vive en un solo lugar de la app (`core/utils/caracteres_permitidos.dart`), para que el filtro, el validador y los mensajes no se contradigan.

**Datos que ya existían:** la base solo revisa el texto cuando es nuevo o cuando cambia. Una publicación vieja con un signo que ya no se permite se puede seguir reservando, vendiendo o borrando, y solo hay que corregir el texto si se edita. Al final de la migración hay una consulta comentada para contar cuántos textos viejos no cumplen la regla.

## 3. Otras protecciones que ya existían

- **Inyección SQL:** la app nunca arma consultas pegando texto. Todo pasa por el API de Supabase (PostgREST), que trata lo que escribe el usuario como dato y no como código. Con o sin esta regla, un `' OR '1'='1` no se ejecuta; ahora además ni siquiera se acepta.
- **Código en pantalla (XSS):** Flutter muestra el texto como texto y no interpreta HTML, así que un `<script>` nunca se ejecuta en la app. La regla nueva cierra la puerta por si esos textos se usan después en una página web, en notificaciones o en reportes.

## 4. Pruebas

| Tipo | Archivo | Qué comprueba |
| :--- | :--- | :--- |
| Base de datos (53 casos SQL en Postgres 16) | probados antes de entregar la migración | Acepta acentos y signos permitidos; rechaza 17 títulos, 5 descripciones y 8 nombres peligrosos; las publicaciones y los perfiles viejos se pueden seguir usando; registrarse, publicar, el Feed y la búsqueda siguen funcionando; las reglas de HU-03 y HU-06 se conservan |
| Unitarias | `test/core/utils/caracteres_permitidos_test.dart` | Cada campo acepta y rechaza los mismos ejemplos que la base, carácter por carácter |
| Unitarias | `publicacion_validator_test.dart`, `perfil_validator_test.dart` | Mensajes por campo; primero se revisa la longitud y después los caracteres |
| API REST simulado (AAA) | `test/api/seguridad_caracteres_api_rest_test.dart` | CP-48 a CP-52 (tabla siguiente) |

| ID | Escenario | Endpoint | Respuesta simulada | Resultado esperado |
| --- | --- | --- | --- | --- |
| CP-48 | Título o descripción con caracteres no permitidos | — | (ninguna) | `PublicacionInvalidaFailure` en el campo exacto; 0 peticiones (ni fotos) |
| CP-49 | Alguien se salta la app con un título peligroso | `POST /rest/v1/publicaciones` | 400 (`23514`, pista `titulo_caracteres`) | Error en el título con el mismo mensaje de la app |
| CP-50 | Descripción peligrosa saltándose la app | `POST /rest/v1/publicaciones` | 400 (pista `descripcion_caracteres`) y 400 sin pista | Error en la descripción; sin pista, rechazo general |
| CP-51 | Nombre con caracteres no permitidos | — | (ninguna) | `NombreInvalidoFailure`; 0 peticiones |
| CP-52 | Nombre peligroso saltándose la app | `POST /rest/v1/usuarios` | 400 (pista `nombre_caracteres`) y 400 sin pista | Mensaje de caracteres; sin pista, mensaje de longitud sin detalles internos |

Resultado: `flutter analyze` sin avisos, todas las pruebas aprobadas (también combinada con la rama de HU-06) y Quality Gate de cobertura en verde.

## 5. Cómo probarlo a mano

1. En "Publicar artículo", intenta escribir `<script>` en el título: los signos `<`, `>` no aparecen.
2. Pega `Calculadora "HP"; <b>` en el título: solo queda `Calculadora HP b`.
3. Escribe un título válido con acentos y signos: `Cálculo (2a ed.) ¿nuevo? $150`. Se publica sin problema.
4. En "Editar perfil", intenta escribir un número o `_` en el nombre: no aparecen.
5. En el SQL Editor de Supabase (opcional), comprueba que existen los dos triggers con la consulta del final de la migración.
