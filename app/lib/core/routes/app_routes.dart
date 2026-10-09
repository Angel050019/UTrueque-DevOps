/// Nombres de rutas de la aplicación. Centralizados aquí para que las
/// pantallas no se referencien por Strings sueltos.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String confirmacionRegistro = '/registro/confirmacion';

  /// Placeholder temporal: el Feed principal se implementará en el
  /// Sprint 2 (HU-05). Por ahora solo confirma que el login funcionó.
  static const String feedPrincipal = '/feed';

  // HU-02: Perfil Académico
  static const String completarPerfil = '/perfil/completar';
  static const String miPerfil = '/perfil';
  static const String editarPerfil = '/perfil/editar';

  // HU-03: Publicación de artículo
  static const String publicarArticulo = '/publicar';
}
