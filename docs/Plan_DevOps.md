# Plan DevOps del Proyecto Móvil - UTrueque

> **Estado del Documento:** En construcción (Borrador Inicial - Sprint 0)

## 1. Resumen del Caso y Objetivos
* **Proyecto:** UTrueque (Marketplace Universitario Móvil)[cite: 2]
* **Institución:** Universidad Tecnológica de San Juan del Río (UTSJR)[cite: 2]
* **Integrantes:** 
  - Diaz Huerta Diego Oziel (Product Owner)[cite: 2]
  - Orduña Garrido Jose Luis (Scrum Master)[cite: 2]
  - Gonzalez Casarrubias Luis Angel (Dev Team)[cite: 2]
  - Cadena Vega Jonathan (Dev Team)[cite: 2]
  - Torres Valeriano Jesus (Product Owner / Support)[cite: 2]

## 2. Arquitectura General
* **Cliente:** Aplicación Móvil en Flutter[cite: 2].
* **Backend BaaS:** Supabase (PostgreSQL, Auth institucional, Realtime WebSockets)[cite: 2].
* **Notificaciones:** Firebase Cloud Messaging (FCM)[cite: 2].

## 3. Ciclo DevOps Aplicado
Fases: Plan -> Code -> Build -> Test -> Package -> Release -> Deploy -> Operate -> Monitor -> Feedback.

## 4. Versionamiento y Ramificación (Git Flow Ligero)
* **`main`:** Rama protegida de producción.
* **`develop`:** Rama de integración continua.
* **`feature/`:** Ramas de características por historia de usuario.
* **`hotfix/`:** Corrección de fallos urgentes en producción[cite: 1].
* **Tag Inicial:** `v0.1.0`[cite: 1].

---
*Nota: El resto de las secciones (estrategia de pruebas, monitoreo y mitigación de riesgos) se integrarán en la siguiente versión del documento.*
