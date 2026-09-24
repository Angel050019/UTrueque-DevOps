# Guía de Contribución y Versionado — UTrueque

¡Bienvenido al proyecto **UTrueque**! Este documento establece las reglas de contribución, la convención de commits y el sistema de versionamiento de la aplicación móvil, con el objetivo de mantener un desarrollo organizado y facilitar la colaboración del equipo.

## 1.Convención de Commits

Se utilizará [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) para mantener un historial de cambios claro y facilitar la generación de notas de lanzamiento.

### Formato

```text
<tipo>(<alcance opcional>): <descripción breve>
```

### Tipos de commits

| Tipo       | Descripción                                       |
| ---------- | ------------------------------------------------- |
| `feat`     | Agrega una nueva funcionalidad.                   |
| `fix`      | Corrige un error.                                 |
| `docs`     | Modifica la documentación.                        |
| `style`    | Realiza cambios de formato sin afectar la lógica. |
| `refactor` | Mejora la estructura del código.                  |
| `test`     | Agrega o modifica pruebas.                        |
| `build`    | Modifica la configuración de compilación.         |
| `chore`    | Realiza tareas de mantenimiento.                  |

### Ejemplos

```text
feat(auth): agregar inicio de sesión institucional
fix(productos): corregir publicación de artículos
docs(readme): actualizar documentación
```

Los commits deberán ser claros, breves y representar cambios específicos.

## 2.Estrategia de Ramificación

Se utilizará una estrategia de ramas para organizar el desarrollo y mantener estable el código.

| Rama       | Propósito                                 |
| ---------- | ----------------------------------------- |
| `main`     | Contiene versiones estables del proyecto. |
| `develop`  | Integra cambios antes de su lanzamiento.  |
| `feature/` | Desarrollo de nuevas funcionalidades.     |
| `fix/`     | Corrección de errores.                    |
| `release/` | Preparación de nuevas versiones.          |
| `hotfix/`  | Correcciones urgentes en producción.      |

Las nuevas funcionalidades y correcciones deberán desarrollarse en ramas independientes y enviarse mediante Pull Requests hacia `develop`. Los lanzamientos aprobados se integrarán en `main`.

## 3.Versionamiento Semántico

UTrueque utilizará el formato de versionamiento semántico `vX.Y.Z`, donde:

* **MAJOR (X):** Cambios incompatibles con versiones anteriores.
* **MINOR (Y):** Nuevas funcionalidades compatibles.
* **PATCH (Z):** Correcciones de errores y mejoras menores.

Ejemplo: `v1.2.3`

Cada lanzamiento deberá identificarse mediante una etiqueta (*Git Tag*) que corresponda con la versión del código.

## 4.Control de Versiones de Compilación

La versión semántica deberá mantenerse sincronizada con la configuración de compilación de la aplicación móvil.

* `buildVersion` / `versionName`: versión visible de la aplicación.
* `versionCode`: identificador numérico único y creciente para cada compilación Android.
* `Git Tag`: identifica el commit correspondiente a una versión oficial.

Antes de cada lanzamiento, estos valores deberán actualizarse y verificarse para garantizar la correcta identificación de la versión publicada.

## 5.Política de Lanzamientos

Para publicar una nueva versión se deberá:

1. Crear una rama `release/vX.Y.Z` desde `develop`.
2. Realizar pruebas y validar los cambios.
3. Actualizar la versión y el número de compilación.
4. Integrar los cambios en `main` y crear el Git Tag correspondiente.
5. Documentar las modificaciones en las notas de lanzamiento (*Release Notes*).

## 6.Contribución y Cumplimiento

Todos los integrantes deberán respetar las convenciones de commits, utilizar las ramas establecidas y solicitar revisión mediante Pull Requests antes de integrar cambios.

Este archivo `CONTRIBUTING.md` deberá mantenerse en la raíz del repositorio, dentro de la rama `main`, y actualizarse cuando se modifiquen las reglas de contribución o versionamiento.

**Producto C:** Archivo `CONTRIBUTING.md` publicado en la rama principal (`main`), con la política de commits, ramificación y lanzamientos de UTrueque.
