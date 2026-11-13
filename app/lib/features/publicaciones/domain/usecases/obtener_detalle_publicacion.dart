import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/publicacion.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: el detalle completo de una publicación (HU-04).
///
/// Siempre se pide al servidor, para mostrar el estado actual (por si se
/// reservó o vendió mientras el estudiante veía el Feed). Si el dueño la
/// borró, el repositorio lanza `PublicacionNoEncontradaFailure`.
class ObtenerDetallePublicacion {
  ObtenerDetallePublicacion(this._repository, this._networkInfo);

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Publicacion> call(String id) async {
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerDetalle(id);
  }
}
