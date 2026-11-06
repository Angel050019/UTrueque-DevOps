import '../../../../core/network/network_info.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: marcar como leída una conversación (HU-07, Escenario 8).
///
/// No avisa errores al estudiante: si no hay conexión o falla, la marca se
/// vuelve a enviar la próxima vez que abra el chat.
class MarcarConversacionLeida {
  MarcarConversacionLeida(this._repository, this._networkInfo);

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;

  /// Devuelve `true` si el servidor la marcó.
  Future<bool> call(String conversacionId) async {
    try {
      if (!await _networkInfo.estaConectado) return false;
      await _repository.marcarLeida(conversacionId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
