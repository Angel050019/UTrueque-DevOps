# PLAN DE PRUEBAS DE API REST Y ESTRATEGIA DE TESTING MÓVIL — UTRUEQUE

**Asignatura:** Gestión del Proceso de Desarrollo de Software
**Unidad II:** Desarrollo e Integración Continua (Tema 4)
**Institución:** Universidad Tecnológica de San Juan del Río (UTSJR)
**Proyecto Integrador:** UTrueque (Plataforma Móvil de Trueque Universitario)
**Fecha:** Septiembre de 2026
**Versión:** 1.0

---

## SECCIÓN 1. PLAN DE PRUEBAS PARA EL API REST (BACKEND UTRUEQUE)

### 1.1 Información General y Alcance

El propósito de este plan es definir la estrategia de automatización de pruebas y análisis estático para el backend (API REST) del proyecto UTrueque, asegurando el cumplimiento de los estándares de calidad definidos por ISO/IEC 25010 y métricas DORA.

**Nombre del Sistema:** UTrueque API REST Backend v1.0

**Arquitectura:** Microservicios / Serverless REST API (Node.js/Java/Supabase)

**Objetivo de Cobertura:** ≥ 80% por módulo funcional.

**Módulos en Alcance:**

* **AuthModule:** Autenticación con correo institucional (`@alumno.utsjr.edu.mx`) y JWT.
* **CatalogModule:** Publicación, edición y catálogo de artículos universitarios.
* **TradeModule:** Solicitud, negociación y aceptación/rechazo de trueques.
* **UserModule:** Perfiles universitarios y reputación.

### 1.2 Entornos de Prueba y Pipeline CI/CD

#### Entorno: Local

**Infraestructura / Herramientas:** Docker Compose + JUnit 5 / Jest + SonarQube Local

**Propósito:** Pruebas unitarias inmediatas durante el desarrollo (Shift-Left Testing).

#### Entorno: Staging (CI)

**Infraestructura / Herramientas:** GitHub Actions Runner (Ubuntu)

**Propósito:** Ejecución automática de pruebas unitarias, análisis estático y de integración en cada Pull Request.

#### Entorno: Pre-Prod

**Infraestructura / Herramientas:** Supabase Staging DB + Newman / k6

**Propósito:** Pruebas de carga, estrés y seguridad antes de publicar la versión candidata.

### 1.3 Matriz de Tipos de Prueba y Criterios de Éxito

| Tipo de Prueba    | Herramienta              | Alcance / Endpoint                  | Criterio de Aceptación                               |
| ----------------- | ------------------------ | ----------------------------------- | ---------------------------------------------------- |
| Unitarias         | JUnit 5 / Jest           | Servicios de negocio y validaciones | Cobertura ≥ 80%, 0 fallos.                           |
| Análisis Estático | SonarQube Cloud          | Todo el código fuente del API       | Quality Gate aprobado (PASSED).                      |
| Integración       | REST Assured / Supertest | `/auth`, `/products`, `/trades`     | Respuestas HTTP correctas (200, 201, 400, 401, 404). |
| Rendimiento       | k6 / JMeter              | `POST /trades` y `GET /products`    | p95 < 200 ms, tasa de error < 1% con 200 RPS.        |
| Seguridad         | OWASP ZAP                | Endpoints protegidos con JWT        | 0 vulnerabilidades de severidad Alta o Crítica.      |

### 1.4 Configuración del Quality Gate en SonarQube

El pipeline de CI/CD detendrá cualquier despliegue (Fail-Fast) si el análisis estático no satisface los siguientes umbrales obligatorios:

**SonarQube Quality Gate Standards (UTSJR - UTrueque):**

* **Bugs:** 0
* **Vulnerabilities:** 0
* **Security Hotspots Reviewed:** 100%
* **Code Smells:** < 10
* **Test Coverage:** ≥ 80.0%
* **Duplicated Lines:** < 3.0%

---

## SECCIÓN 2. CASOS DE PRUEBA UNITARIAS DEL API REST (PATRÓN AAA)

A continuación se presentan 5 casos de prueba unitarios críticos desarrollados con el Patrón AAA (Arrange - Act - Assert) utilizando JUnit 5 y Mockito para el backend de UTrueque.

### 2.1 CP-01. Autenticación Exitosa con Correo Institucional UTSJR

**Código de prueba:**

```java
package com.utrueque.api.auth;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtProvider jwtProvider;

    @InjectMocks
    private AuthService authService;

    @Test
    @DisplayName("CP-01: Debería autenticar correctamente a un alumno con correo institucional @alumno.utsjr.edu.mx")
    void deberiaAutenticarAlumnoInstitucionalExitosamente() {

        // ARRANGE
        String emailValido = "20233tn000@alumno.utsjr.edu.mx";
        String password = "PasswordSegura123!";
        User usuarioSimulado = new User("101", emailValido, "HASHED_PASS", "ALUMNO");

        when(userRepository.findByEmail(emailValido)).thenReturn(java.util.Optional.of(usuarioSimulado));
        when(userRepository.checkPassword(password, "HASHED_PASS")).thenReturn(true);
        when(jwtProvider.generateToken(usuarioSimulado)).thenReturn("eyJhbGciOiJIUzI1NiJ9.mockToken");

        // ACT
        AuthResponse response = authService.login(new LoginRequest(emailValido, password));

        // ASSERT
        assertNotNull(response, "La respuesta de autenticación no debe ser nula");
        assertEquals("eyJhbGciOiJIUzI1NiJ9.mockToken", response.getToken(), "El JWT generado debe coincidir");
        assertEquals(emailValido, response.getEmail(), "El correo retornado debe ser el mismo registrado");
        verify(userRepository, times(1)).findByEmail(emailValido);
    }
}
```

### 2.2 CP-02. Rechazo de Registro con Dominio de Correo No Institucional

**Código de prueba:**

```java
package com.utrueque.api.auth;

import com.utrueque.api.exceptions.InvalidDomainException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class RegisterServiceTest {

    @InjectMocks
    private AuthService authService;

    @Test
    @DisplayName("CP-02: Debería lanzar InvalidDomainException si el correo no pertenece al dominio UTSJR")
    void deberiaRechazarRegistroConCorreoInvalido() {

        // ARRANGE
        RegisterRequest requestInvalido = new RegisterRequest(
            "Juan Pérez",
            "juan.perez@gmail.com",
            "Password123!"
        );

        // ACT & ASSERT
        InvalidDomainException exception = assertThrows(
            InvalidDomainException.class,
            () -> authService.register(requestInvalido),
            "Debe lanzar la excepción al usar un correo externo"
        );

        assertTrue(
            exception.getMessage().contains("Solo se permiten correos @alumno.utsjr.edu.mx o @utsjr.edu.mx"),
            "El mensaje de error debe indicar la restricción de dominio"
        );
    }
}
```

### 2.3 CP-03. Creación de Publicación de Producto Válido para Trueque

**Código de prueba:**

```java
package com.utrueque.api.catalog;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductService productService;

    @Test
    @DisplayName("CP-03: Debería crear una nueva publicación de producto con estado DISPONIBLE")
    void deberiaCrearProductoParaTruequeExitosamente() {

        // ARRANGE
        ProductRequest request = new ProductRequest(
            "Calculadora Casio fx-991EX",
            "Calculadora científica en excelente estado",
            "LIBROS_Y_MATERIALES",
            "USER_123"
        );

        Product productoGuardado = new Product(
            "PROD_999",
            request.getTitle(),
            request.getDescription(),
            request.getCategory(),
            "DISPONIBLE",
            request.getUserId()
        );

        when(productRepository.save(any(Product.class))).thenReturn(productoGuardado);

        // ACT
        ProductResponse response = productService.createProduct(request);

        // ASSERT
        assertNotNull(response.getId(), "El ID del producto generado no debe ser nulo");
        assertEquals("DISPONIBLE", response.getStatus(), "El estado inicial debe ser DISPONIBLE");
        assertEquals("Calculadora Casio fx-991EX", response.getTitle());
        verify(productRepository, times(1)).save(any(Product.class));
    }
}
```

### 2.4 CP-04. Transición de Estado al Aceptar una Oferta de Trueque

**Código de prueba:**

```java
package com.utrueque.api.trade;

import com.utrueque.api.catalog.ProductRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TradeServiceTest {

    @Mock
    private TradeRepository tradeRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private TradeService tradeService;

    @Test
    @DisplayName("CP-04: Debería cambiar el estado de la oferta a ACEPTADO y actualizar productos a EN_PROCESO")
    void deberiaAceptarOfertaDeTruequeCorrectamente() {

        // ARRANGE
        String tradeId = "TRADE_500";
        Trade tradePendiente = new Trade(tradeId, "PROD_A", "PROD_B", "PENDIENTE");

        when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(tradePendiente));

        // ACT
        TradeResult result = tradeService.acceptTradeOffer(tradeId);

        // ASSERT
        assertEquals("ACEPTADO", result.getTradeStatus(), "El estado de la negociación debe ser ACEPTADO");
        verify(tradeRepository).updateStatus(tradeId, "ACEPTADO");
        verify(productRepository).updateStatus("PROD_A", "EN_PROCESO");
        verify(productRepository).updateStatus("PROD_B", "EN_PROCESO");
    }
}
```

### 2.5 CP-05. Manejo de Excepción para Producto No Encontrado en el Catálogo

**Código de prueba:**

```java
package com.utrueque.api.catalog;

import com.utrueque.api.exceptions.ResourceNotFoundException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProductSearchServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductService productService;

    @Test
    @DisplayName("CP-05: Debería lanzar ResourceNotFoundException si el ID del producto no existe")
    void deberiaLanzarExcepcionCuandoProductoNoExiste() {

        // ARRANGE
        String idInexistente = "PROD_NO_EXISTE_999";
        when(productRepository.findById(idInexistente)).thenReturn(Optional.empty());

        // ACT & ASSERT
        ResourceNotFoundException exception = assertThrows(
            ResourceNotFoundException.class,
            () -> productService.getProductById(idInexistente),
            "Debe arrojar una excepción 404 personalizada"
        );

        assertEquals(
            "Producto con ID PROD_NO_EXISTE_999 no fue encontrado",
            exception.getMessage()
        );

        verify(productRepository, times(1)).findById(idInexistente);
    }
}
```

---

## SECCIÓN 3. INVESTIGACIÓN: PRUEBAS Y HERRAMIENTAS PARA APLICACIONES MÓVILES (FLUTTER / MOBILE)

### 3.1 Niveles de Prueba en el Desarrollo Móvil

A diferencia de las aplicaciones web o backend, las aplicaciones móviles dependen del hardware nativo, resoluciones de pantalla variables, versiones del sistema operativo (Android/iOS), estados de red y ciclo de vida de la aplicación.

**Niveles de prueba:**

#### Nivel 1: Pruebas Unitarias

**Business Logic / BLoC / State Management**

#### Nivel 2: Pruebas de Widgets y Renderizado

**Widget Tests / Golden Tests**

#### Nivel 3: Pruebas de Integración Móvil

**Integration Test Driver**

#### Nivel 4: Pruebas E2E y Dispositivos Reales

**Patrol / Firebase Test Lab**

### Pruebas Unitarias Móviles

Validan clases, controladores de estado (BLoC, Provider, Riverpod), repositorios y parseo de JSON sin renderizar la interfaz gráfica.

### Pruebas de Widgets

Validan la interacción de la UI aislada en un lienzo simulado. Comprueban que los botones respondan, que los campos de texto muestren mensajes de error y la disposición gráfica.

### Golden Tests

Comparación píxel por píxel de capturas de pantalla de widgets contra una imagen dorada (golden file) de referencia para evitar regresiones visuales.

### Pruebas de Integración Móvil

Verifican el flujo completo de la app conectada con servicios reales o simulados (red, almacenamiento local SQLite/Hive, notificaciones push FCM) ejecutándose dentro de un emulador o dispositivo real.

### Pruebas E2E en Granjas de Dispositivos

Pruebas automatizadas en docenas de dispositivos físicos reales con diferentes marcas (Samsung, Xiaomi, iPhone), tamaños de pantalla y versiones de Android/iOS para validar compatibilidad.

### Pruebas de Rendimiento y Recursos Móviles

#### FPS (Frames Per Second)

Garantizar 60 FPS (o 120 FPS en pantallas de alta tasa de refresco) para evitar parpadeos (jank).

#### Consumo de Memoria RAM y CPU

Detección de fugas de memoria (memory leaks).

#### Batería y Uso de Red

Medición del consumo energético y comportamiento en redes inestables (3G, 4G, 5G o modo offline).

### 3.2 Matriz Comparativa de Herramientas para Testing Móvil

| Herramienta           | Tipo / Propósito              | Plataforma            | Integración CI/CD            | Ventajas Principales                                                                                    |
| --------------------- | ----------------------------- | --------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------- |
| **flutter_test**      | Unitarias y Widgets           | Flutter (Dart)        | Excelente (Nativo)           | Ejecución ultra rápida en memoria, nativo de Flutter.                                                   |
| **Patrol**            | E2E e Integración Avanzada    | Flutter (Android/iOS) | GitHub Actions, Codemagic    | Permite interactuar con diálogos nativos del sistema operativo, como permisos, cámara y notificaciones. |
| **Appium**            | E2E Automático                | Híbrido / Nativo      | Jenkins, GitHub Actions      | Multiplataforma, estándar de la industria basado en WebDriver.                                          |
| **Firebase Test Lab** | Granja de Dispositivos        | Android / iOS         | Google Cloud, GitHub Actions | Ejecuta pruebas en dispositivos físicos reales alojados en Google Cloud.                                |
| **Detox**             | E2E React Native / Móvil      | iOS / Android         | Bitrise, GitHub Actions      | Ejecución rápida, sincronización automática con la UI.                                                  |
| **SonarQube**         | Análisis Estático (Dart/Java) | Multiplataforma       | GitHub Actions, GitLab CI    | Análisis de calidad, vulnerabilidades y deuda técnica en el código móvil.                               |

### 3.3 Integración de Pruebas Móviles en el Pipeline CI/CD de UTrueque

El siguiente workflow representa la ejecución automatizada de pruebas para la aplicación móvil de UTrueque en GitHub Actions.

#### Configuración del Workflow

```yaml
name: Mobile & API Quality Pipeline - UTrueque

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  mobile-tests:
    name: Flutter Unit, Widget & Static Analysis
    runs-on: ubuntu-latest

    steps:
      - name: Checkout del Código
        uses: actions/checkout@v4

      - name: Configurar Java JDK 17
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Configurar SDK de Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          flutter-version: '3.29.2'
          cache: true

      - name: Instalar Dependencias
        run: |
          cd app
          flutter pub get

      - name: Verificación de Formato y Linter
        run: |
          cd app
          flutter analyze

      - name: Ejecutar Pruebas Unitarias y de Widgets con Cobertura
        run: |
          cd app
          flutter test --coverage

      - name: Escaneo de SonarQube Cloud (Quality Gate)
        uses: SonarSource/sonarcloud-github-action@v2.0.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## CONCLUSIONES Y RECOMENDACIONES DEVOPS

### Estrategia Shift-Left

Al ejecutar los 5 casos de prueba del API REST y los análisis estáticos desde la fase de Pull Request, se reduce el costo de corrección de errores en hasta un 80% en comparación con la detección en etapa de producción.

### Quality Gate como Guardián

La regla de bloquear el despliegue cuando la cobertura cae por debajo del 80% o existen vulnerabilidades detectadas por SonarQube garantiza un producto robusto para la comunidad universitaria de la UTSJR.

### Automatización Móvil

La inclusión de Widget Tests y herramientas como Patrol o Firebase Test Lab resuelve el reto de la heterogeneidad de dispositivos móviles, asegurando que UTrueque funcione correctamente en cualquier smartphone.
