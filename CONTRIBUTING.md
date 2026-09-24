#Guía de Contribución y Versionado — UTrueque

¡Bienvenido al proyecto **UTrueque**! Este documento establece las reglas de contribución, convenciones de commits y versionamiento de la aplicación móvil, con el objetivo de mantener un desarrollo organizado y facilitar la colaboración del equipo.

## 1.Convención de Commits

Se utilizará [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) para mantener un historial claro y facilitar la generación de notas de lanzamiento (*Release Notes*).

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
fix(login): corregir validación de credenciales
docs(readme): actualizar documentación
```

Los commits deberán ser claros, breves y representar cambios específicos.

## 2.Estrategia de Ramificación

UTrueque utiliza una estrategia de ramas basada en Git Flow simplificado para organizar el desarrollo y mantener estable el código.

| Rama       | Propósito                                     |
| ---------- | --------------------------------------------- |
| `main`     | Contiene las versiones estables del proyecto. |
| `develop`  | Integra los cambios antes de su lanzamiento.  |
| `feature/` | Desarrolla nuevas funcionalidades.            |
| `hotfix/`  | Corrige errores urgentes.                     |
| `release/` | Prepara y valida nuevas versiones.            |

Actualmente, el repositorio cuenta con las ramas `main`, `develop`, `feature/HU-01-auth-institucional` y `hotfix/0.1.1-fix-login`.

Las ramas `feature/`, `hotfix/` y `release/` se crearán según las necesidades del proyecto.

### Flujo de trabajo

1. Crear una rama de trabajo desde `develop`.
2. Realizar los cambios y registrarlos mediante commits convencionales.
3. Enviar un Pull Request hacia `develop` para su revisión.
4. Integrar los cambios aprobados.
5. Preparar y validar las versiones antes de integrarlas en `main`.

Las correcciones urgentes deberán integrarse también en `develop` para evitar que el error reaparezca en futuras versiones.

## 3.Versionamiento Semántico

Se utilizará el esquema de versionamiento semántico `vX.Y.Z`, que permite identificar los cambios realizados en cada versión.

| Componente  | Descripción                                     |
| ----------- | ----------------------------------------------- |
| `MAJOR (X)` | Cambios incompatibles con versiones anteriores. |
| `MINOR (Y)` | Nuevas funcionalidades compatibles.             |
| `PATCH (Z)` | Correcciones de errores y mejoras menores.      |

**Ejemplo:** `v1.2.3`

Cada lanzamiento oficial deberá contar con una etiqueta (*Git Tag*) que identifique la versión del código fuente.

## 4.Control de Versiones de Compilación

La versión semántica deberá mantenerse sincronizada con la configuración de compilación de la aplicación móvil.

* `buildVersion` / `versionName`: identifica la versión visible de la aplicación.
* `versionCode`: identificador numérico único y creciente para cada compilación Android.
* `Git Tag`: identifica el commit correspondiente a una versión oficial.

Antes de cada lanzamiento, se deberán actualizar y verificar estos valores para asegurar la correcta identificación de la versión publicada.

## 5.Política de Lanzamientos

Para generar una nueva versión de UTrueque, se deberá:

1. Crear una rama `release/vX.Y.Z` desde `develop`, cuando sea necesario.
2. Realizar pruebas y validar los cambios.
3. Actualizar la versión semántica y el número de compilación.
4. Integrar los cambios aprobados en `main`.
5. Crear el Git Tag correspondiente y documentar los cambios en las notas de lanzamiento (*Release Notes*).

Las versiones oficiales deberán identificarse con etiquetas siguiendo el formato `vX.Y.Z`.

## 6.Pull Requests y Contribución

Todos los integrantes deberán seguir las convenciones de commits y utilizar las ramas establecidas.

Antes de integrar cambios, se deberá:

* Crear un Pull Request con una descripción clara.
* Verificar que los cambios funcionen correctamente.
* Resolver conflictos y atender las observaciones de revisión.
* Obtener aprobación antes de integrar cambios en `main`.

