import '../entities/aviso_chat.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: suscribirse al tiempo real (HU-07, Escenario 3; patrón
/// Observer). Los Cubits son los observadores: escuchan este Stream y
/// cancelan su suscripción al cerrarse.
class EscucharChat {
  EscucharChat(this._repository);

  final ChatRepository _repository;

  Stream<AvisoChat> call() => _repository.avisos();
}
