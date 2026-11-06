import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../entities/pagina_mensajes.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: los mensajes de una conversación, de 30 en 30 (HU-07,
/// Escenarios 2 y 9). Con [antesDe] trae los anteriores.
class ObtenerMensajes {
  ObtenerMensajes(this._repository, this._networkInfo);

  static const int mensajesPorPagina = 30;

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;

  Future<PaginaMensajes> call(String conversacionId, {CursorFeed? antesDe}) async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.obtenerMensajes(conversacionId, antesDe: antesDe, limite: mensajesPorPagina);
  }
}
