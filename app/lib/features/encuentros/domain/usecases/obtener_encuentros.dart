import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/encuentro.dart';
import '../repositories/encuentros_repository.dart';

/// Caso de uso: los encuentros de una conversación, para dibujar las
/// tarjetas y el aviso del encuentro confirmado (HU-08).
class ObtenerEncuentros {
  ObtenerEncuentros(this._repository, this._networkInfo);

  final EncuentrosRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<Encuentro>> call(String conversacionId) async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.obtenerEncuentros(conversacionId);
  }
}
