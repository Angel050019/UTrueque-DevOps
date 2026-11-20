import '../../../../core/network/network_info.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: el número del globo del ícono de mensajes (HU-07,
/// Escenario 8). Si no hay conexión o falla, devuelve `null` y el globo
/// conserva el número que tenía.
class ObtenerTotalNoLeidos {
  ObtenerTotalNoLeidos(this._repository, this._networkInfo);

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;

  Future<int?> call() async {
    try {
      if (!await _networkInfo.estaConectado) return null;
      return await _repository.totalNoLeidos();
    } catch (_) {
      return null;
    }
  }
}
