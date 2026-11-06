import 'package:flutter/widgets.dart';

import 'cubit/gestionar_publicacion_state.dart';

/// Keys de "Mis publicaciones" (HU-06). Las pruebas buscan los widgets por
/// estas Keys, así el diseño puede cambiar sin romper pruebas.
/// Si rediseñas, CONSERVA las Keys.
class MisPublicacionesKeys {
  MisPublicacionesKeys._();

  static const Key pantalla = Key('mis_publicaciones_pantalla');
  static const Key activasTab = Key('mis_publicaciones_activas_tab');
  static const Key finalizadasTab = Key('mis_publicaciones_finalizadas_tab');
  static const Key lista = Key('mis_publicaciones_lista');
  static const Key cargando = Key('mis_publicaciones_cargando');
  static const Key vacio = Key('mis_publicaciones_vacio');
  static const Key publicarBoton = Key('mis_publicaciones_publicar_boton');
  static const Key error = Key('mis_publicaciones_error');
  static const Key reintentarBoton = Key('mis_publicaciones_reintentar_boton');
  static const Key cargandoMas = Key('mis_publicaciones_cargando_mas');
  static const Key errorMas = Key('mis_publicaciones_error_mas');
  static const Key reintentarMasBoton = Key('mis_publicaciones_reintentar_mas_boton');
  static const Key finDeLista = Key('mis_publicaciones_fin_de_lista');

  /// Botón "Gestionar" de la publicación con ese id.
  static Key gestionar(String id) => Key('mis_publicaciones_gestionar_$id');
}

/// Keys de la hoja "Gestionar publicación" (HU-06).
class GestionarKeys {
  GestionarKeys._();

  static const Key hoja = Key('gestionar_hoja');
  static const Key estado = Key('gestionar_estado');
  static const Key editarBoton = Key('gestionar_editar_boton');
  static const Key finalizadaAviso = Key('gestionar_finalizada_aviso');
  static const Key enviando = Key('gestionar_enviando');
  static const Key confirmacion = Key('gestionar_confirmacion');
  static const Key confirmarBoton = Key('gestionar_confirmar_boton');
  static const Key cancelarBoton = Key('gestionar_cancelar_boton');

  /// Botón de cada operación: reservar, liberar, marcarVendido o borrar.
  static Key operacion(OperacionGestion operacion) => Key('gestionar_${operacion.name}');
}
