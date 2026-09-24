# Guía de Contribución y Versionado - UTrueque

¡Bienvenido al proyecto **UTrueque**! Este documento define la política oficial de mensajes de commits, la estrategia de ramificación y el esquema de versionamiento semántico para el desarrollo de la aplicación móvil.

---

## 1. Convención de Commits (Conventional Commits)

Todos los mensajes de commit deben seguir la especificación [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) para mantener un historial limpio y facilitar la generación automatizada de notas de lanzamiento (*Release Notes*).

### Formato del Commit

```text
<tipo>(<alcance opcional>): <descripción breve en presente o imperativo>
```

### Tipos Permitidos (`<tipo>`)

* **`feat`**: Nueva funcionalidad para la aplicación móvil (ejemplo: inicio de sesión o catálogo).
* **`fix`**: Corrección de errores o *bugs* en el código.
* **`docs`**: Cambios en la documentación del proyecto (`README.md`, `Plan_DevOps.md`, etc.).
* **`style`**: Ajustes de formato, espaciado o linters que no afectan la lógica del código.
* **`refactor`**: Reestructuración del código sin corregir errores ni agregar funcionalidades.
* **`test`**: Adición o corrección de pruebas unitarias o de integración en Flutter.
* **`ci`**: Cambios en los flujos de integración continua (GitHub Actions, workflows).
* **`chore`**: Tareas administrativas, actualización de dependencias o configuraciones sin impacto en producción.

### Ejemplos Válidos

```text
feat(auth): agrega autenticación con correo institucional
fix(ui): corrige desbordamiento de texto en la tarjeta de producto
docs(contributing): añade guía de contribución y política de versionado
ci(workflow): actualiza la versión de Java a JDK 17 en el pipeline
```

---

## 2. Control de Versionado Semántico (SemVer)

UTrueque utiliza el versionamiento semántico (`vX.Y.Z`) vinculado con la configuración de Flutter definida en el archivo `pubspec.yaml`.

### Estructura de la Versión

El formato utilizado será `vX.Y.Z`, acompañado de un número de compilación en Flutter: `X.Y.Z+BUILD`.

Ejemplo: `v0.1.0` (build `1`).

* **`X` (MAJOR / Mayor):** Cambios incompatibles en la API o rediseños arquitectónicos importantes.
* **`Y` (MINOR / Menor):** Nuevas funcionalidades compatibles con versiones anteriores.
* **`Z` (PATCH / Parche):** Correcciones de errores menores y parches de seguridad.
* **`BUILD` (Build Number):** Número incremental utilizado para identificar cada compilación de la aplicación.

### Sincronización con Flutter (`pubspec.yaml`)

Al liberar una versión estable en la rama `main`, la versión en `pubspec.yaml` deberá coincidir con la versión publicada.

```yaml
# pubspec.yaml
version: 0.1.0+1
```

* `0.1.0`: Versión visible de la aplicación (`versionName`).
* `1`: Número de compilación (`versionCode` / `buildVersion`).

El número de compilación deberá incrementarse en cada nueva compilación distribuida.

---

## 3. Flujo de Trabajo con Ramas (Git Flow Ligero)

El proyecto utilizará las siguientes ramas para organizar el desarrollo:

1. **`main`**: Rama principal que contiene versiones estables. Solo recibe cambios mediante Pull Requests aprobados desde `develop` o `hotfix/*`.
2. **`develop`**: Rama de integración donde se consolidan las funcionalidades desarrolladas y probadas.
3. **`feature/<nombre-tarea>`**: Ramas creadas desde `develop` para desarrollar nuevas funcionalidades o Historias de Usuario.
   Ejemplo: `feature/HU-01-auth-institucional`.
4. **`hotfix/<nombre-fix>`**: Ramas creadas desde `main` para corregir errores críticos en versiones estables.

---

## 4. Proceso para Enviar un Pull Request (PR)

1. Crear una rama de trabajo desde `develop`, utilizando el prefijo correspondiente.

2. Realizar commits atómicos siguiendo la convención establecida.

3. Ejecutar las pruebas locales de Flutter antes de subir los cambios:

   ```bash
   flutter analyze
   flutter test
   ```

4. Abrir un Pull Request y completar la plantilla obligatoria (`pull_request_template.md`).

5. Solicitar al menos **una revisión de un compañero** antes de realizar el merge.

---

## 5. Publicación del Archivo y Producto C

Para completar el Producto C, se deberá guardar este documento como `CONTRIBUTING.md` en la raíz del repositorio y subirlo a la rama principal (`main`).

El commit deberá seguir la convención establecida:

```bash
docs(contributing): añade reglas de contribución y versionado semántico
```

**Producto C:** Archivo `CONTRIBUTING.md` publicado en la rama `main`, con las políticas de commits, ramificación y versionamiento de UTrueque.
