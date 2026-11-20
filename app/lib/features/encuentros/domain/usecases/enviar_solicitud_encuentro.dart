import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/solicitud_encuentro.dart';
import '../factories/creadores_solicitud.dart';
import '../repositories/encuentros_repository.dart';

/// Caso de uso: proponer, aceptar, rechazar o cancelar un encuentro (HU-08).
///
/// Patrón Factory Method: recibe cualquier [CreadorSolicitudEncuentro] y le
/// pide la solicitud con `crear()`, sin saber cuál es.
///
/// 1. El creador revisa las reglas sin tocar la red; si algo falla, lanza el
///    fallo y no se envía nada.
/// 2. Revisa la conexión (Escenario 13).
/// 3. Envía la solicitud. El servidor vuelve a revisar todo y crea la
///    tarjeta, que llega a los dos por el tiempo real del chat.
class EnviarSolicitudEncuentro {
  EnviarSolicitudEncuentro(this._repository, this._networkInfo);

  final EncuentrosRepository _repository;
  final NetworkInfo _networkInfo;

  Future<SolicitudEncuentro> call(CreadorSolicitudEncuentro creador) async {
    final SolicitudEncuentro solicitud = creador.crear();
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    await _repository.enviar(solicitud);
    return solicitud;
  }
}
