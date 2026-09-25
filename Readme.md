# UTrueque - Marketplace Universitario Móvil

![UTrueque CI Pipeline](https://github.com/Angel050019/UTrueque-DevOps/actions/workflows/ci.yml/badge.svg)
![Version](https://img.shields.io/badge/version-v0.1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

##  Descripción del Proyecto
UTrueque es una plataforma móvil orientada a la comunidad universitaria de la UTSJR que facilita la compra, venta, trueque y donación segura de materiales académicos, libros y herramientas. La plataforma garantiza un entorno de confianza exigiendo autenticación obligatoria mediante correo institucional (`@alumno.utsjr.edu.mx`).

---

## Enlaces Principales
* **Tablero de Trabajo (Sprint 0):** [GitHub Projects Board](#) *(https://github.com/users/Angel050019/projects/1)*
* **Plan DevOps del Proyecto Móvil:** [Ver /docs/Plan_DevOps.md](./docs/Plan_DevOps.md)
* **Matriz y Normas de Comunicación:** [Ver /docs/Comunicacion.md](./docs/Comunicacion.md)

---

## Arquitectura y Stack Tecnológico
* **Cliente Móvil:** Flutter (Dart) con Arquitectura Limpia (Clean Architecture).
* **Backend as a Service (BaaS):** Supabase (PostgreSQL, Auth institucional y WebSockets Realtime).
* **Notificaciones Push:** Firebase Cloud Messaging (FCM).
* **CI/CD:** GitHub Actions.

---

## Cómo Construir y Ejecutar el Proyecto Localmente

### Prerrequisitos
* **Flutter SDK:** Versión `>=3.19.0` (Canal `stable`).
* **Dart SDK:** Versión `>=3.3.0`.
* **Java JDK:** Versión `17`.
* **Android Studio / VS Code** con extensiones de Flutter y Dart.

### Pasos de Instalación
1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/Angel050019/UTrueque-DevOps.git](https://github.com/Angel050019/UTrueque-DevOps.git)
   cd UTrueque-DevOps/app
2. **Instalar dependencias:**
    ```bash
    flutter pub get
3. **Verificar el codigo(Linting & Analysis):**
   ```bash
    flutter analyze
4. Ejecutar la aplicación en enumaldor o dispositivo físico:
    ```bash
    flutter run
    
---

## Política de Ramas y Versionamiento (Git Flow Ligero)
* **main:** Rama protegida de producción estable.
* **develop:** Rama principal para la integración continua de características.
* **feature/:** Ramas independientes para el desarrollo de Historias de Usuario (Ejemplo: feature/HU-01-auth-institucional).
* **hotfix/:** Correcciones urgentes aplicadas sobre producción.

---

## Convención de Commits:
* (feat:, fix:, docs:, ci:, test:)

---

## Tag Semántico:
* v0.1.0(Prototipo Inicial - Sprint 0)


---

  ## Integrantes del Equipo
  * **Diaz Huerta Oziel - Product Owner**
  * **Orduña Garrido Jose Luis - Scrum Master**
  * **Gonzalez Casarrubias Luis Angel - Develop Team**
  * **Cadena Vega Jonathan - Develop Team**
  * **Torres Valeriano Jesus - Product Owner/Support**

---
