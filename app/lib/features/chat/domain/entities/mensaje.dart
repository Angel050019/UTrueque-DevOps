import 'package:equatable/equatable.dart';

/// Un mensaje de una conversación (HU-07). No se edita ni se borra.
class Mensaje extends Equatable {
  const Mensaje({
    required this.id,
    required this.conversacionId,
    required this.autorId,
    required this.texto,
    required this.creadoEn,
  });

  final String id;
  final String conversacionId;
  final String autorId;
  final String texto;
  final DateTime creadoEn;

  /// ¿Lo escribió el estudiante [idUsuario]?
  bool esDe(String? idUsuario) => idUsuario != null && idUsuario == autorId;

  @override
  List<Object?> get props => [id, conversacionId, autorId, texto, creadoEn];
}
