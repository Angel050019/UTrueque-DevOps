import 'package:flutter/widgets.dart';

/// Keys de los widgets importantes del Detalle de la publicación (HU-04).
/// Las pruebas buscan los widgets por estas Keys, así el diseño puede
/// cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
class DetalleKeys {
  DetalleKeys._();

  static const Key pantalla = Key('detalle_pantalla');
  static const Key cargando = Key('detalle_cargando');
  static const Key error = Key('detalle_error');
  static const Key reintentarBoton = Key('detalle_reintentar_boton');
  static const Key noEncontrado = Key('detalle_no_encontrado');
  static const Key volverFeedBoton = Key('detalle_volver_feed_boton');

  static const Key carrusel = Key('detalle_carrusel');
  static const Key indicadorFotos = Key('detalle_indicador_fotos');
  static const Key titulo = Key('detalle_titulo');
  static const Key precioOModalidad = Key('detalle_precio_modalidad');
  static const Key estado = Key('detalle_estado');
  static const Key avisoEstado = Key('detalle_aviso_estado');
  static const Key fecha = Key('detalle_fecha');
  static const Key descripcion = Key('detalle_descripcion');
  static const Key dueno = Key('detalle_dueno');
  static const Key esMiaEtiqueta = Key('detalle_es_mia');
  static const Key contactarBoton = Key('detalle_contactar_boton');
  static const Key gestionarBoton = Key('detalle_gestionar_boton');
}
