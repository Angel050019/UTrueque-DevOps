import 'package:flutter/widgets.dart';

/// Keys del chat (HU-07). Las pruebas buscan los widgets por estas Keys, así
/// el diseño puede cambiar sin romper pruebas. Si rediseñas, CONSERVA las Keys.
class ChatKeys {
  ChatKeys._();

  static const Key pantalla = Key('chat_pantalla');
  static const Key encabezado = Key('chat_encabezado');
  static const Key lista = Key('chat_lista');
  static const Key cargando = Key('chat_cargando');
  static const Key error = Key('chat_error');
  static const Key reintentarBoton = Key('chat_reintentar_boton');
  static const Key bienvenida = Key('chat_bienvenida');
  static const Key cargandoAnteriores = Key('chat_cargando_anteriores');
  static const Key errorAnteriores = Key('chat_error_anteriores');
  static const Key reintentarAnterioresBoton = Key('chat_reintentar_anteriores_boton');
  static const Key campoTexto = Key('chat_campo_texto');
  static const Key enviarBoton = Key('chat_enviar_boton');
  static const Key cerradaAviso = Key('chat_cerrada_aviso');

  /// Burbuja del mensaje con ese id.
  static Key burbuja(String id) => Key('chat_burbuja_$id');
}

/// Keys de la bandeja de mensajes (HU-07).
class BandejaKeys {
  BandejaKeys._();

  static const Key pantalla = Key('bandeja_pantalla');
  static const Key lista = Key('bandeja_lista');
  static const Key cargando = Key('bandeja_cargando');
  static const Key vacia = Key('bandeja_vacia');
  static const Key error = Key('bandeja_error');
  static const Key reintentarBoton = Key('bandeja_reintentar_boton');

  /// Fila de la conversación con ese id.
  static Key conversacion(String id) => Key('bandeja_conversacion_$id');

  /// Globo de no leídos de la conversación con ese id.
  static Key noLeidos(String id) => Key('bandeja_no_leidos_$id');
}
