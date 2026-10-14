/// Nombres de rutas de la aplicación. Centralizados aquí para que las
/// pantallas no se referencien por Strings sueltos.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String confirmacionRegistro = '/registro/confirmacion';

  /// HU-04: Feed principal de publicaciones.
  static const String feedPrincipal = '/feed';

  // HU-02: Perfil Académico
  static const String completarPerfil = '/perfil/completar';
  static const String miPerfil = '/perfil';
  static const String editarPerfil = '/perfil/editar';

  // HU-03: Publicación de artículo
  static const String publicarArticulo = '/publicar';

  // HU-04: Feed de publicaciones. Recibe un `DetallePublicacionArgs`.
  static const String detallePublicacion = '/publicacion';
}
