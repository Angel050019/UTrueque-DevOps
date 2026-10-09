import 'package:flutter/widgets.dart';

import '../domain/entities/modalidad.dart';

/// Keys de los widgets importantes de "Publicar artículo".
/// Las pruebas buscan los widgets por estas Keys, así el diseño puede
/// cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
class PublicacionKeys {
  PublicacionKeys._();

  static const Key tituloField = Key('publicacion_titulo_field');
  static const Key descripcionField = Key('publicacion_descripcion_field');
  static const Key categoriaSelector = Key('publicacion_categoria_selector');
  static const Key precioField = Key('publicacion_precio_field');
  static const Key agregarFotoBoton = Key('publicacion_agregar_foto_boton');
  static const Key errorFotos = Key('publicacion_error_fotos');
  static const Key errorModalidad = Key('publicacion_error_modalidad');
  static const Key publicarBoton = Key('publicacion_publicar_boton');
  static const Key reintentarBoton = Key('publicacion_reintentar_boton');
  static const Key cargando = Key('publicacion_cargando');
  static const Key errorCarga = Key('publicacion_error_carga');

  /// Botón de cada modalidad: Venta, Intercambio o Gratis.
  static Key modalidad(Modalidad modalidad) => Key('publicacion_modalidad_${modalidad.valor}');

  /// Botón "quitar" de la foto número [indice] (0 = portada).
  static Key quitarFoto(int indice) => Key('publicacion_quitar_foto_$indice');

  /// Botón flotante "Publicar" del Feed.
  static const Key feedPublicarBoton = Key('feed_publicar_boton');

  /// Lista "Publicaciones recientes" del Feed y sus estados.
  static const Key feedLista = Key('feed_publicaciones_lista');
  static const Key feedVacio = Key('feed_publicaciones_vacio');
  static const Key feedCargando = Key('feed_publicaciones_cargando');
  static const Key feedError = Key('feed_publicaciones_error');
  static const Key feedReintentarBoton = Key('feed_publicaciones_reintentar');

  /// Tarjeta de la publicación con ese id.
  static Key tarjeta(String id) => Key('feed_publicacion_$id');
}
