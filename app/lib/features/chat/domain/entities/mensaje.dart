import 'package:equatable/equatable.dart';

/// HU-08: qué clase de mensaje es. Los de encuentro los crea el servidor al
/// proponer, aceptar, rechazar o cancelar un punto de encuentro, y el chat
/// los dibuja como tarjetas.
enum TipoMensaje {
  texto('texto'),
  propuesta('propuesta'),
  aceptado('aceptado'),
  rechazado('rechazado'),
  cancelado('cancelado');

  const TipoMensaje(this.valor);

  /// Texto que se guarda en la columna `tipo`.
  final String valor;

  /// Un valor desconocido (o vacío, como en los mensajes de HU-07) se toma
  /// como texto normal.
  static TipoMensaje desdeValor(String? valor) =>
      TipoMensaje.values.firstWhere((t) => t.valor == valor, orElse: () => TipoMensaje.texto);
}

/// Un mensaje de una conversación (HU-07). No se edita ni se borra.
class Mensaje extends Equatable {
  const Mensaje({
    required this.id,
    required this.conversacionId,
    required this.autorId,
    required this.texto,
    required this.creadoEn,
    this.tipo = TipoMensaje.texto,
    this.encuentroId,
  });

  final String id;
  final String conversacionId;
  final String autorId;
  final String texto;
  final DateTime creadoEn;

  /// HU-08: texto normal o tarjeta de encuentro.
  final TipoMensaje tipo;

  /// HU-08: el encuentro de la tarjeta; `null` en los mensajes normales.
  final String? encuentroId;

  /// ¿Lo escribió el estudiante [idUsuario]?
  bool esDe(String? idUsuario) => idUsuario != null && idUsuario == autorId;

  /// HU-08: ¿se dibuja como tarjeta de encuentro?
  bool get esDeEncuentro => tipo != TipoMensaje.texto && encuentroId != null;

  @override
  List<Object?> get props => [id, conversacionId, autorId, texto, creadoEn, tipo, encuentroId];
}
