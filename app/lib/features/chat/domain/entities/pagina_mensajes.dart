import 'package:equatable/equatable.dart';

import '../../../publicaciones/domain/entities/pagina_feed.dart';
import 'mensaje.dart';

/// Una página de mensajes (HU-07, Escenario 9): los MÁS NUEVOS primero,
/// como los entrega el servidor. [siguiente] es el cursor para pedir los
/// anteriores (`null` si ya no hay más). Usa el mismo cursor que el Feed.
class PaginaMensajes extends Equatable {
  const PaginaMensajes({required this.mensajes, this.siguiente});

  final List<Mensaje> mensajes;
  final CursorFeed? siguiente;

  bool get hayAnteriores => siguiente != null;

  @override
  List<Object?> get props => [mensajes, siguiente];
}
