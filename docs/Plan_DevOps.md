# Plan DevOps del Proyecto Móvil - UTrueque

## 1. Resumen del Caso y Objetivos
UTrueque es una aplicación móvil diseñada para facilitar la compra, venta, trueque y donación de insumos académicos dentro de la comunidad universitaria. Garantiza un entorno seguro exigiendo autenticación mediante correo institucional (`@alumno.utsjr.edu.mx`) y filtrado por carrera.

### Objetivos
* Implementar un ciclo ágil DevOps estructurado en 10 Sprints de 1 semana.
* Integrar pruebas continuas para asegurar una estabilidad del 99.5% libre de fallos (Crash-Free Rate).
* Automatizar la integración y despliegue del proyecto mediante GitHub Actions y Firebase.

---

## 2. Arquitectura General y Dependencias
* **Cliente Móvil:** Desarrollado en Flutter (Dart) con arquitectura limpia.
* **Backend como Servicio (BaaS):** Supabase (PostgreSQL, Autenticación y WebSockets Realtime).
* **Servicio Externo:** Firebase Cloud Messaging (FCM) para notificaciones push.

---

## 3. Ciclo DevOps Aplicado

| Fase | Objetivo | Herramienta | Artefactos | Criterio de Hecho (DoD) |
| :--- | :--- | :--- | :--- | :--- |
| **Plan** | Planificación de Sprints | GitHub Projects | Product Backlog | Historias con Criterios de Aceptación (Gherkin) |
| **Code** | Desarrollo cliente y backend | VS Code, Flutter, Git | Commits, Pull Requests | PR aprobado por 1 reviewer |
| **Build** | Compilación continua | GitHub Actions | Artefactos Android/iOS | Build sin errores sintácticos |
| **Test** | Validación de calidad | Flutter Test | Reporte de Cobertura | Cobertura de código ≥ 70% |
| **Package** | Generación de ejecutable | Fastlane, Gradle | APK / AAB | Artefacto firmado |
| **Release** | Control de versiones | Git Tags, GitHub Releases | Release v0.x.y | Tag semántico publicado |
| **Deploy** | Distribución a testers | Firebase App Distribution | APK para QA | Checklist de pruebas OK |
| **Operate** | Operación de servicios BaaS | Supabase Dashboard | Logs de BD y API | Servicios operando sin latencia[ |
| **Monitor** | Análisis de caídas y errores | Firebase Crashlytics | Métricas de Crashes | Alertas automáticas activas |
| **Feedback** | Gestión de incidencias | GitHub Issues | Registro de errores | Tickets agregados al Backlog |

---

## 4. Versionamiento y Ramificación (Git Flow Ligero)
* **`main`:** Rama estable protegida orientada a producción.
* **`develop`:** Rama de integración continua.
* **`feature/`:** Ramas independientes derivadas de `develop` para el desarrollo de historias de usuario.
* **`hotfix/`:** Ramas para solución de errores urgentes derivadas de `main`.
* **Tagging:** Uso de versionado semántico (SemVer) iniciando en `v0.1.0`.

---

## 5. CI/CD (Integración y Despliegue Continuo)
* **Disparadores (Triggers):** Ejecución automática en `push` hacia `develop` y en `pull_request` con destino a `main`.
* **Criterios de Merge:** Aprobación de 1 revisor y ejecución con resultado PASSED en el pipeline de GitHub Actions.

---

## 6. Estrategia de Pruebas
* **Pruebas Unitarias:** Validación de lógica de negocio (reglas de correo institucional y precios).
* **Pruebas de UI/Widget:** Validación de componentes visuales en Flutter.
* **Criterios de Entrada/Salida:** Entrada: Funcionalidad completa en rama feature. Salida: Cobertura ≥ 70% sin fallos en pipeline.

---

## 7. Estrategia de Despliegue
* **Alfa / Beta:** Pruebas internas distribuidas vía Firebase App Distribution para retroalimentación de la comunidad universitaria.
* **Producción:** Despliegue final en la Google Play Store mediante compilados AAB firmados.

---

## 8. Monitoreo y Métricas
* **Herramientas:** Firebase Crashlytics para rastreo de errores en vivo.
* **Métricas SLI/SLO:** SLO de disponibilidad del servicio en 99.5% y tasa libre de errores en 99%.

---

## 9. Riesgos y Planes de Mitigación
1. **Límite de conexiones simultáneas en backend free tier:** Optimización de consultas PostgreSQL y límites en WebSockets.
2. **Rechazo de actualización en tiendas:** Pruebas preliminares con políticas de contenido e imágenes.
3. **Fallo en compilación automatizada:** Entorno virtual fijo en GitHub Actions con Flutter canal estable.

---

## 10. Runbook de Fallas Comunes
* **Build Roto en CI:** Verificar logs en la pestaña Actions, corregir error en la rama local `feature` y realizar commit de ajuste.
* **Credenciales/Tokens Expirados:** Regenerar llaves API en el panel de Supabase y actualizar Variables de Entorno en GitHub Secrets.
