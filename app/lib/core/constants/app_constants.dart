/// Constantes globales de la aplicación UTrueque.
class AppConstants {
  AppConstants._();

  /// Dominio institucional obligatorio para registro e inicio de sesión.
  /// Ver HU-01: Registro e Inicio de Sesión Institucional.
  static const String dominioInstitucional = '@utsjr.edu.mx';

  /// Nombre de la variable de entorno donde se inyecta la URL de Supabase
  /// (definida en GitHub Secrets / --dart-define, nunca hardcodeada).
  static const String supabaseUrlEnvKey = 'SUPABASE_URL';

  /// Nombre de la variable de entorno donde se inyecta la anon key de Supabase.
  static const String supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  /// Nombre de la tabla de perfiles de usuario en Supabase (Postgres).
  static const String tablaUsuarios = 'usuarios';

  // ---------------------------------------------------------------------
  // HU-02: Perfil Académico
  // ---------------------------------------------------------------------

  /// Tablas del catálogo académico (División → Carrera).
  static const String tablaDivisiones = 'divisiones';
  static const String tablaCarreras = 'carreras';

  /// Bucket de Supabase Storage para fotos de perfil. Cada usuario solo
  /// puede escribir en `avatars/<su id>/`.
  static const String bucketAvatars = 'avatars';

  /// Regla de negocio: imágenes de máximo 5 MB.
  static const int tamanoMaximoImagenBytes = 5 * 1024 * 1024;

  /// Longitud permitida del nombre a mostrar (igual que en la base de datos).
  static const int nombreLongitudMinima = 3;
  static const int nombreLongitudMaxima = 50;
}
