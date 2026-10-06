# UTrueque - Aplicación Móvil (Flutter)


Cliente móvil de UTrueque, construido en Flutter con Arquitectura Limpia (Clean Architecture) y Supabase como Backend as a Service.

## Estructura de carpetas

```
lib/
  core/                     # Código transversal: constantes, errores, red, rutas, tema, utilidades, widgets compartidos
  features/
    auth/                   # HU-01: Registro e Inicio de Sesión Institucional
      data/                 # Datasources, modelos y repositorios concretos (habla con Supabase)
      domain/                # Entidades, contratos de repositorio y casos de uso (no depende de Supabase)
      presentation/          # Cubit, páginas y widgets de UI
    perfil/                  # HU-02: Perfil Académico (División → Carrera, nombre, foto)
    feed/                    # Placeholder temporal del Feed (HU-05)
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
2. Configurar las llaves de Supabase (una sola vez):
   ```bash
   cp env.example.json env.json
   ```
   Edita `env.json` con la URL y la anon key del proyecto (pídelas al equipo).
   `env.json` está en `.gitignore`: **nunca se sube al repo**.

   Ejecutar en Chrome o en un celular conectado por USB:
   ```bash
   flutter devices                                  # lista los dispositivos
   flutter run -d chrome --dart-define-from-file=env.json
   flutter run -d <id-del-celular> --dart-define-from-file=env.json
   ```
   Generar un APK para instalarlo en cualquier Android:
   ```bash
   flutter build apk --release --dart-define-from-file=env.json
   # queda en build/app/outputs/flutter-apk/app-release.apk
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


## Configuración de Supabase para HU-02

Aplicar en el SQL Editor de Supabase el archivo `supabase/migrations/20260929120000_hu02_perfil_academico.sql` (se puede correr más de una vez). Crea:

* Tablas `divisiones` y `carreras` (catálogo **provisional**, se reemplaza por el oficial sin tocar la app).
* Columnas nuevas en `usuarios`: `division_id`, `carrera_id`, `foto_url`, `perfil_completo`, `created_at`, `updated_at`.
* Políticas RLS: cualquier usuario autenticado lee perfiles; cada quien solo edita el suyo.
* Bucket público `avatars` (JPG/PNG, máx. 5 MB); cada usuario solo escribe en `avatars/<su id>/`.

La guía para el diseño visual de las pantallas de perfil está en `docs/Sprint2_Guia_Diseno.md`.
