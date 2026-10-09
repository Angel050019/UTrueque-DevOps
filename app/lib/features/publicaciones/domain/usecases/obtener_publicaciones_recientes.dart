import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/publicacion.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: publicaciones recientes para el Feed (Disponibles y
/// Reservadas, de la más nueva a la más vieja).
///
/// Es una versión sencilla del Feed para mostrar lo que se publica en HU-03.
/// El Feed completo (búsqueda y filtros por división y carrera) llega en su
/// propia historia.
class ObtenerPublicacionesRecientes {
  ObtenerPublicacionesRecientes(this._repository, this._networkInfo);

  /// Cuántas publicaciones se piden como máximo.
  static const int limitePorDefecto = 20;

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<Publicacion>> call({int limite = limitePorDefecto}) async {
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerPublicacionesRecientes(limite: limite);
  }
}
