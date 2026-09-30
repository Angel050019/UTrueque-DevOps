# UTrueque - Aplicación Móvil (Flutter)


Cliente móvil de UTrueque, construido en Flutter con Arquitectura Limpia (Clean Architecture) y Supabase como Backend as a Service.

## Estructura de carpetas

```
lib/
  core/                     # Código transversal: constantes, errores, red, utilidades, widgets compartidos
  features/
    auth/                   # HU-01: Registro e Inicio de Sesión Institucional
      data/                 # Datasources, modelos y repositorios concretos (habla con Supabase)
      domain/                # Entidades, contratos de repositorio y casos de uso (no depende de Supabase)
      presentation/          # Cubit, páginas y widgets de UI
    feed/                    # Placeholder temporal del Feed (HU-05, Sprint 2)
```

## Prerrequisitos

* Flutter SDK `>=3.19.0` (canal `stable`)
* Dart SDK `>=3.3.0`
* Un proyecto de Supabase con Auth habilitado

## Ejecutar localmente

1. Instalar dependencias:
   ```bash
   flutter pub get
   ```
2. Ejecutar pasando las credenciales de Supabase (nunca se hardcodean en el código):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=tu-anon-key
   ```
3. Verificar el análisis estático antes de subir cualquier cambio:
   ```bash
   flutter analyze
   ```
4. Correr las pruebas unitarias:
   ```bash
   flutter test
   ```

## Configuración de Supabase para HU-01

En el panel de Supabase, la tabla `usuarios` debe existir con al menos las columnas `id` (uuid, FK a `auth.users.id`), `nombre_mostrar`, `division` y `carrera`, ya que `AuthRemoteDataSourceImpl` la consulta al iniciar sesión para completar el perfil.

