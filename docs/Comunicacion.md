# Plan y Guía de Comunicación del Equipo - UTrueque

Este documento define la herramienta oficial, la matriz comparativa de selección, el dictamen de justificación y las normas de uso de comunicación para el desarrollo de la aplicación móvil **UTrueque**.

---

## 1. Matriz Comparativa de Herramientas de Comunicación

Se evaluaron 4 plataformas de comunicación bajo 7 criterios clave puntuados en una escala del 1 al 5 (donde 1 es insatisfactorio y 5 es excelente):

| Criterio (Puntaje 1-5) | Slack | MS Teams | Discord | Google Chat |
| :--- | :---: | :---: | :---: | :---: |
| **Hilos y Conversaciones** | 5 | 4 | 3 | 3 |
| **Reuniones / Calendario / Videollamadas** | 3 | 5 | 3 | 3 |
| **Integraciones Dev (GitHub / CI/CD)** | 5 | 4 | 4 | 3 |
| **Seguridad / Cumplimiento Institucional** | 4 | 5 | 3 | 3 |
| **Historial (Plan Gratuito / Institucional)** | 2 | 4 | 4 | 3 |
| **Costo Educativo / Accesibilidad** | 4 | 4 | 5 | 5 |
| **Facilidad y Experiencia Móvil** | 5 | 3 | 5 | 4 |
| **Puntaje Total** | **28** | **29** | **27** | **24** |

---

## 2. Dictamen de Selección (Justificación Técnica)

Se selecciona **Microsoft Teams** como la herramienta oficial de comunicación para el equipo de desarrollo del proyecto UTrueque. La decisión se fundamenta principalmente en que el equipo ya cuenta con experiencia previa en la plataforma y es la herramienta estándar utilizada activamente en otras asignaturas institucionales, lo que elimina la curva de aprendizaje y centraliza la gestión académica.

### Ventajas Clave
1. **Integración con el Entorno Institucional y Calendario:** Facilita la programación y sincronización de eventos ágiles (Daily Standups, Sprint Planning y Demos) directamente con el correo universitario.
2. **Llamadas y Screen Sharing:** Soporta sesiones de *pair programming* y revisiones de código en vivo sin las restricciones de tiempo de los planes gratuitos de otras herramientas.
3. **Estructura de Canales y Conectores:** Permite organizar discusiones por tema e integrar Webhooks entrantes para recibir notificaciones de GitHub Actions y despliegues automáticos.

### Riesgos y Mitigaciones
* **Riesgo:** La experiencia en dispositivos móviles para alertas instantáneas de CI/CD puede ser menos ágil en comparación con chats dedicados exclusivamente a mensajería rápida.
* **Mitigación:** Configurar notificaciones prioritarias e integraciones de bots con menciones directas en el canal `#ops` ante fallos críticos en los pipelines de GitHub Actions.

---

## 3. Configuración del Entorno de Trabajo

El equipo operará en un equipo/workspace dedicado en Microsoft Teams con la siguiente estructura obligatoria de canales:

* **`#anuncios`:** Información oficial del proyecto, fechas límite e hitos de Sprint.
* **`#dev`:** Discusión técnica de desarrollo, arquitectura en Flutter/Supabase y revisión de código.
* **`#qa`:** Pruebas de software, reporte de bugs y retroalimentación de funcionalidad.
* **`#ops`:** Canal automatizado para alertas de CI/CD, builds rotos e incidencias.
* **`#dudas`:** Consultas generales entre miembros del equipo sobre tareas assigned.
* **`#random`:** Conversación informal y temas no relacionados al desarrollo directo.

---

## 4. Normas y Guía de Convivencia (Playbook de Comunicación)

### SLAs de Respuesta (Tiempos de Atención)
* **Horario de Atención Principal:** Lunes a Viernes de 08:00 a 18:00 hrs.
* **Consultas Generales (`#dudas`, `#dev`):** Tiempo máximo de respuesta de **2 horas** dentro del horario operativo.
* **Incidentes Críticos (`#ops` / Build Roto):** Tiempo máximo de atención de **30 minutos**.

### Uso de Hilos y Organización
* Toda respuesta a un mensaje debe realizarse dentro del **hilo correspondiente** para mantener la coherencia y no saturar el canal general.
* Para hablar de un Pull Request o Issue de GitHub, se debe incluir el enlace directo o el ID correspondiente (`#ID`).

### Uso Responsable de @Menciones
* **`@canal` / `@todos`:** Reservado exclusivamente para anuncios críticos o emergencias de build roto en `#ops`.
* **Menciones Individuales (`@nombre`):** Utilizadas cuando se requiere la aprobación explícita de un revisor de código o Product Owner.

### Formato para Reportar Incidentes en `#ops`
Al reportar un error manual o falla de pipeline, utilizar el siguiente formato:
```text
INCIDENCIA DETECTADA
- Módulo/Pantalla: [Ej. Autenticación / Registro]
- Rama afectada: [develop / feature/HU-XX]
- Descripción breve: [Detalle del fallo]
- Enlace al Log / PR: [URL de GitHub Actions]
