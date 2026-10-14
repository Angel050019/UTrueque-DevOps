import 'package:flutter/widgets.dart';

/// Keys de los widgets importantes del Feed (HU-04).
/// Las pruebas buscan los widgets por estas Keys, así el diseño puede
/// cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
///
/// Las Keys de cada tarjeta siguen en `PublicacionKeys.tarjeta(id)`.
class FeedKeys {
  FeedKeys._();

  static const Key publicarBoton = Key('feed_publicar_boton');
  static const Key miPerfilBoton = Key('feed_mi_perfil_boton');
  static const Key lista = Key('feed_publicaciones_lista');
  static const Key vacio = Key('feed_publicaciones_vacio');
  static const Key cargando = Key('feed_publicaciones_cargando');
  static const Key error = Key('feed_publicaciones_error');
  static const Key reintentarBoton = Key('feed_publicaciones_reintentar');

  /// Final de la lista: spinner de "cargando más", mensaje de "ya viste
  /// todas" o error al cargar más con su botón para reintentar.
  static const Key cargandoMas = Key('feed_cargando_mas');
  static const Key finDeLista = Key('feed_fin_de_lista');
  static const Key errorMas = Key('feed_error_mas');
  static const Key reintentarMasBoton = Key('feed_reintentar_mas_boton');
}
