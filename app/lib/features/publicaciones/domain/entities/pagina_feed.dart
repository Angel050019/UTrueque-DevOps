import 'package:equatable/equatable.dart';

import 'publicacion.dart';

/// Marca dónde se quedó el Feed: la fecha y el id de la ÚLTIMA publicación
/// que ya se mostró. La siguiente página trae las anteriores a ella.
///
/// [fecha] es el texto tal como lo manda el servidor (con microsegundos).
/// No se convierte a `DateTime` porque en la web `DateTime` solo guarda
/// milisegundos y se podrían saltar publicaciones creadas en el mismo
/// milisegundo.
class CursorFeed extends Equatable {
  const CursorFeed({required this.fecha, required this.id});

  final String fecha;
  final String id;

  @override
  List<Object?> get props => [fecha, id];
}

/// Una página del Feed (HU-04): las publicaciones y, si hay más, el cursor
/// para pedir la siguiente.
class PaginaFeed extends Equatable {
  const PaginaFeed({required this.publicaciones, this.siguiente});

  final List<Publicacion> publicaciones;

  /// `null` cuando ya no hay más publicaciones.
  final CursorFeed? siguiente;

  bool get hayMas => siguiente != null;

  @override
  List<Object?> get props => [publicaciones, siguiente];
}
