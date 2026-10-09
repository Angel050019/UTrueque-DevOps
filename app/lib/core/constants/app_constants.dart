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

  // ---------------------------------------------------------------------
  // HU-03: Publicación de artículo (issue #4)
  // ---------------------------------------------------------------------

  /// Tablas de publicaciones y de su catálogo de categorías.
  static const String tablaPublicaciones = 'publicaciones';
  static const String tablaCategorias = 'categorias';

  /// Bucket de Storage para las fotos de los artículos. Cada usuario solo
  /// puede escribir en `publicaciones/<su id>/`.
  static const String bucketPublicaciones = 'publicaciones';

  /// Fotos por publicación (igual que en la base de datos).
  static const int fotosPorPublicacionMaximo = 5;

  /// Longitudes permitidas (iguales a las restricciones de la base).
  static const int tituloLongitudMinima = 3;
  static const int tituloLongitudMaxima = 80;
  static const int descripcionLongitudMinima = 10;
  static const int descripcionLongitudMaxima = 500;
}
