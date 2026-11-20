import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/punto_encuentro.dart';
import '../repositories/encuentros_repository.dart';

/// Caso de uso: el catálogo de lugares oficiales para la hoja "Proponer
/// punto de encuentro" (HU-08, Escenario 5).
class ObtenerPuntosEncuentro {
  ObtenerPuntosEncuentro(this._repository, this._networkInfo);

  final EncuentrosRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<PuntoEncuentro>> call() async {
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.obtenerPuntos();
  }
}
