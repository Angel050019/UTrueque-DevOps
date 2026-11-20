import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/conversacion.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: la bandeja de mensajes (HU-07, Escenario 7).
class ObtenerConversaciones {
  ObtenerConversaciones(this._repository, this._networkInfo);

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<Conversacion>> call() async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.obtenerConversaciones();
  }
}
