import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/estado_publicacion.dart';
import '../entities/publicacion.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: Reservar, volver a Disponible o marcar como Vendido una
/// publicación propia (HU-06, Escenarios 3, 4, 5 y 9). Patrón State.
///
/// 1. El estado actual decide si la [accion] se permite. Si no, lanza
///    `TransicionNoPermitidaFailure` sin tocar la red.
/// 2. Revisa la conexión (Escenario 12).
/// 3. Manda SOLO el estado nuevo. El servidor vuelve a revisar la
///    transición contra el estado real (por si cambió en otro dispositivo)
///    y que la publicación sea del estudiante.
class CambiarEstadoPublicacion {
  CambiarEstadoPublicacion(this._repository, this._networkInfo);

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Publicacion> call(Publicacion publicacion, AccionEstado accion) async {
    final EstadoPublicacion nuevo = publicacion.estado.aplicar(accion);
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.cambiarEstado(publicacion.id, nuevo);
  }
}
