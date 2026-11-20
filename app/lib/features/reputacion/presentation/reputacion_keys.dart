import 'package:flutter/widgets.dart';

/// Keys de la reputación (HU-09). Las pruebas buscan los widgets por estas
/// Keys, así el diseño puede cambiar sin romper pruebas. Si rediseñas,
/// CONSERVA las Keys.
class ReputacionKeys {
  ReputacionKeys._();

  // Etiqueta compacta (Detalle, chat)
  static const Key etiqueta = Key('reputacion_etiqueta');
  static const Key sinCalificaciones = Key('reputacion_sin_calificaciones');

  // Hoja "¿A quién se lo vendiste?"
  static const Key hojaComprador = Key('reputacion_hoja_comprador');
  static const Key compradoresCargando = Key('reputacion_compradores_cargando');
  static const Key compradoresError = Key('reputacion_compradores_error');
  static const Key compradoresReintentar = Key('reputacion_compradores_reintentar');
  static const Key compradoresVacio = Key('reputacion_compradores_vacio');
  static const Key fueraDeUTrueque = Key('reputacion_fuera_de_utrueque');
  static const Key confirmarVenta = Key('reputacion_confirmar_venta');
  static const Key cancelarVenta = Key('reputacion_cancelar_venta');

  /// La opción de quien tiene esa conversación.
  static Key comprador(String conversacionId) => Key('reputacion_comprador_$conversacionId');

  // Hoja "Calificar"
  static const Key hojaCalificar = Key('reputacion_hoja_calificar');
  static const Key comentario = Key('reputacion_comentario');
  static const Key contador = Key('reputacion_contador');
  static const Key mensajeError = Key('reputacion_mensaje_error');
  static const Key enviarCalificacion = Key('reputacion_enviar_calificacion');

  /// La estrella número [n] (1 a 5) del selector.
  static Key estrella(int n) => Key('reputacion_estrella_$n');

  // Aviso "Califica tu trato" (chat y Mi perfil)
  static Key avisoCalificar(String ventaId) => Key('reputacion_aviso_$ventaId');
  static Key calificarBoton(String ventaId) => Key('reputacion_calificar_$ventaId');

  // Mi perfil
  static const Key seccion = Key('reputacion_seccion');
  static const Key promedio = Key('reputacion_promedio');
  static const Key avisoAjustado = Key('reputacion_aviso_ajustado');
  static const Key resumenError = Key('reputacion_resumen_error');
  static const Key resumenReintentar = Key('reputacion_resumen_reintentar');
  static const Key recibidas = Key('reputacion_recibidas');
  static const Key recibidasVacio = Key('reputacion_recibidas_vacio');
  static const Key recibidasError = Key('reputacion_recibidas_error');
  static const Key verMas = Key('reputacion_ver_mas');

  /// La barra de [n] estrellas del resumen.
  static Key barra(int n) => Key('reputacion_barra_$n');

  /// Una calificación recibida.
  static Key recibida(String id) => Key('reputacion_recibida_$id');
}
