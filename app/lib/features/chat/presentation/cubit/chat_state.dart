import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';

/// Estados del chat (HU-07). Todos conocen la [conversacion] para dibujar el
/// encabezado (otro estudiante y publicación).
abstract class ChatState extends Equatable {
  const ChatState(this.conversacion);

  final Conversacion conversacion;

  @override
  List<Object?> get props => [conversacion];
}

class ChatCargando extends ChatState {
  const ChatCargando(super.conversacion);
}

/// No se pudieron cargar los mensajes (Escenarios 14 y 15).
class ChatError extends ChatState {
  const ChatError(super.conversacion, this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  bool get sinConexion => failure is SinConexionFailure;

  @override
  List<Object?> get props => [conversacion, failure];
}

/// El chat está listo.
class ChatListo extends ChatState {
  const ChatListo(
    super.conversacion, {
    required this.mensajes,
    this.siguiente,
    this.cargandoAnteriores = false,
    this.errorAnteriores,
    this.enviando = false,
    this.cerradaPorServidor = false,
    this.aviso,
  });

  /// Del más viejo al más nuevo (el más nuevo va abajo).
  final List<Mensaje> mensajes;

  /// Cursor para pedir los mensajes anteriores; `null` si ya no hay.
  final CursorFeed? siguiente;
  final bool cargandoAnteriores;
  final String? errorAnteriores;

  /// Se está enviando un mensaje (el botón "Enviar" se deshabilita).
  final bool enviando;

  /// El servidor avisó que la publicación se vendió o se borró.
  final bool cerradaPorServidor;

  /// Mensaje de un solo uso (SnackBar), por ejemplo sin conexión al enviar.
  final String? aviso;

  bool get hayAnteriores => siguiente != null;

  /// Escenario 11: en lugar del campo de texto se muestra un aviso.
  bool get cerrada => cerradaPorServidor || !conversacion.aceptaMensajes;

  ChatListo copyWith({
    List<Mensaje>? mensajes,
    CursorFeed? Function()? siguiente,
    bool? cargandoAnteriores,
    String? Function()? errorAnteriores,
    bool? enviando,
    bool? cerradaPorServidor,
    String? Function()? aviso,
  }) {
    return ChatListo(
      conversacion,
      mensajes: mensajes ?? this.mensajes,
      siguiente: siguiente != null ? siguiente() : this.siguiente,
      cargandoAnteriores: cargandoAnteriores ?? this.cargandoAnteriores,
      errorAnteriores: errorAnteriores != null ? errorAnteriores() : this.errorAnteriores,
      enviando: enviando ?? this.enviando,
      cerradaPorServidor: cerradaPorServidor ?? this.cerradaPorServidor,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }

  @override
  List<Object?> get props =>
      [conversacion, mensajes, siguiente, cargandoAnteriores, errorAnteriores, enviando, cerradaPorServidor, aviso];
}
