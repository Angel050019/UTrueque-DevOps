# Planeación del Sprint 1 - UTrueque

## 1. Datos generales

| Campo | Valor |
| :--- | :--- |
| **Sprint** | Sprint 1 |
| **Duración** | 1 semana |
| **Fecha de inicio** | Lunes de la semana en curso |
| **Fecha de cierre (Sprint Review)** | Viernes de la semana en curso |
| **Rama base** | `develop` |
| **Rama de trabajo** | `feature/HU-01-auth-institucional` |

## 2. Sprint Goal

Dejar funcional, integrado a Supabase y fusionado a `develop` con el pipeline de CI en verde, el flujo completo de **registro e inicio de sesión con correo institucional** (HU-01), que es la base de acceso de toda la aplicación: sin esto, ninguna otra historia de usuario puede probarse de punta a punta.

## 3. Historias seleccionadas del Product Backlog

| ID | Historia | Prioridad | Estimación |
| :--- | :--- | :--- | :--- |
| **HU-01** | Registro e Inicio de Sesión Institucional | Alta (bloqueante) | 8 pts |

Se seleccionó únicamente HU-01 para este sprint porque es prerrequisito de todas las demás (feed, publicaciones, chat, etc. requieren un usuario autenticado), y porque el equipo aún no tiene código Flutter en el repositorio: el primer sprint también carga con el costo de dejar montado el esqueleto del proyecto (arquitectura de carpetas, dependencias base, conexión a Supabase), que después servirá para las historias del Sprint 2 en adelante.

## 4. Desglose de tareas por integrante

| Tarea | Responsable | Rol |
| :--- | :--- | :--- |
| Definir y validar criterios de aceptación (Gherkin) de HU-01 | Diaz Huerta Oziel | Product Owner |
| Configurar tablero del Sprint 1, dar seguimiento diario y remover impedimentos | Orduña Garrido Jose Luis | Scrum Master |
| Crear proyecto en Supabase (Auth + tabla `usuarios`) y compartir credenciales vía GitHub Secrets | Orduña Garrido Jose Luis | Scrum Master |
| Montar el esqueleto del proyecto Flutter (Clean Architecture, `pubspec.yaml`, dependencias) | Gonzalez Casarrubias Luis Angel | Develop Team |
| Implementar pantalla de Registro + validación de dominio `@alumno.utsjr.edu.mx` | Gonzalez Casarrubias Luis Angel | Develop Team |
| Implementar pantalla de Inicio de Sesión + manejo de estado sin conexión | Cadena Vega Jonathan | Develop Team |
| Implementar capa de datos (repositorio de autenticación contra Supabase) y pruebas unitarias del validador de correo | Cadena Vega Jonathan | Develop Team |
| Validar manualmente cada escenario Gherkin contra el build antes de aprobar el PR | Torres Valeriano Jesus | Product Owner / Support |
| Revisar y aprobar el Pull Request hacia `develop` (mínimo 1 revisor, CI en verde) | Diaz Huerta Oziel | Product Owner |

## 5. Criterios de aceptación (Gherkin) - HU-01

```gherkin
Historia: HU-01 Registro e Inicio de Sesión Institucional
Como estudiante universitario
Quiero registrarme e iniciar sesión utilizando mi correo institucional
Para garantizar que interactúo en un entorno seguro y exclusivo de la comunidad universitaria

  Escenario 1: Registro exitoso con correo institucional
    Dado que el estudiante no tiene una cuenta en UTrueque
    Cuando ingresa un correo con dominio "@alumno.utsjr.edu.mx", una contraseña válida y su confirmación
    Y presiona el botón "Registrarse"
    Entonces el sistema crea la cuenta en Supabase
    Y el estudiante recibe un correo de confirmación
    Y es dirigido a la pantalla de Confirmación de registro

  Escenario 2: Registro rechazado por correo no institucional
    Dado que el estudiante está en la pantalla de Registro
    Cuando ingresa un correo que no termina en "@alumno.utsjr.edu.mx"
    Y presiona el botón "Registrarse"
    Entonces el sistema no crea la cuenta
    Y se muestra el mensaje "Debes usar tu correo institucional para registrarte"

  Escenario 3: Inicio de sesión sin conexión a internet
    Dado que el dispositivo del estudiante no tiene conexión a internet
    Cuando el estudiante intenta iniciar sesión con credenciales válidas
    Entonces el sistema no envía la solicitud a Supabase
    Y se muestra una alerta de "Sin conexión a internet. Verifica tu red e inténtalo de nuevo"

  Escenario 4: Inicio de sesión exitoso
    Dado que el estudiante ya tiene una cuenta confirmada
    Cuando ingresa su correo institucional y contraseña correctos
    Y presiona el botón "Iniciar sesión"
    Entonces el sistema valida las credenciales contra Supabase
    Y el estudiante es dirigido al Feed principal

  Escenario 5: Credenciales incorrectas
    Dado que el estudiante ya tiene una cuenta
    Cuando ingresa una contraseña incorrecta
    Entonces el sistema no inicia sesión
    Y se muestra el mensaje "Correo o contraseña incorrectos"
```

## 6. Definición de Hecho (Definition of Done) del Sprint 1

- [ ] Código en la rama `feature/HU-01-auth-institucional`, con commits siguiendo Conventional Commits.
- [ ] Los 5 escenarios Gherkin de la sección 5 pasan manualmente contra el build.
- [ ] `flutter analyze` sin errores en el pipeline de GitHub Actions.
- [ ] Pull Request hacia `develop` con la plantilla del repositorio completa y al menos 1 aprobación.
- [ ] Pipeline de CI en estado PASSED antes del merge (Squash and Merge).
- [ ] Demo del flujo de registro/login funcionando contra Supabase en el Sprint Review del viernes.

## 7. Riesgos específicos del sprint

- **Configuración de Supabase pendiente al inicio del sprint:** bloquea la integración real hasta que se compartan las credenciales. Mitigación: el Scrum Master las genera y comparte el primer día del sprint (lunes), y mientras tanto el equipo de desarrollo avanza con la UI y el validador de dominio de forma desacoplada.
- **Primer `pubspec.yaml` del repositorio:** al agregarlo, el pipeline de CI (`ci.yml`) ejecutará `flutter pub get` y `flutter analyze` por primera vez; puede requerir un ajuste rápido de versión de Flutter/Dart en el workflow si difiere del SDK local del equipo.
