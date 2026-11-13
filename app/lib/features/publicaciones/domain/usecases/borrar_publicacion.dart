import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/publicacion.dart';
import '../errors/publicacion_failures.dart';
import '../repositories/publicacion_repository.dart';
import 'subir_fotos_publicacion.dart';

/// Caso de uso: borrar una publicación Disponible y sus fotos
/// (HU-06, Escenario 8).
///
/// 1. Solo una publicación Disponible se borra (patrón State).
/// 2. Revisa la conexión (Escenario 12).
/// 3. Borra la publicación (lo importante) y después sus fotos. Si las
///    fotos no se pudieran borrar, no se muestra error: quedan en la carpeta
///    del propio estudiante y no afectan a nadie.
class BorrarPublicacion {
  BorrarPublicacion(this._repository, this._networkInfo);

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<void> call(Publicacion publicacion) async {
    if (!publicacion.estado.sePuedeBorrar) throw const AccionNoPermitidaFailure();
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    final List<String> fotos = await _repository.borrarPublicacion(publicacion.id);
    await eliminarSinFallar(_repository, fotos);
  }
}
