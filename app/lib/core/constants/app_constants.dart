/// Constantes globales de la aplicación UTrueque.
class AppConstants {
  AppConstants._();

  /// Dominio institucional obligatorio para registro e inicio de sesión.
  /// Ver HU-01: Registro e Inicio de Sesión Institucional.
  static const String dominioInstitucional = '@alumno.utsjr.edu.mx';

  /// Nombre de la variable de entorno donde se inyecta la URL de Supabase
  /// (definida en GitHub Secrets / --dart-define, nunca hardcodeada).
  static const String supabaseUrlEnvKey = 'SUPABASE_URL';

  /// Nombre de la variable de entorno donde se inyecta la anon key de Supabase.
  static const String supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  /// Nombre de la tabla de perfiles de usuario en Supabase (Postgres).
  static const String tablaUsuarios = 'usuarios';
}
