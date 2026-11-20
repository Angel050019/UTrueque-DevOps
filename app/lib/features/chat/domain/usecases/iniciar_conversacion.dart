import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../entities/conversacion.dart';
import '../errors/chat_failures.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso: "Contactar al vendedor" (HU-07, Escenarios 1, 2, 4 y 5).
///
/// 1. Una publicación propia no se contacta (Escenario 4).
/// 2. Revisa la conexión (Escenario 14).
/// 3. El servidor abre la conversación si ya existía, o la crea si la
///    publicación está Disponible y el perfil está completo.
/// Devuelve la conversación lista para abrir el chat.
class IniciarConversacion {
  IniciarConversacion(this._repository, this._networkInfo);

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Conversacion> call(Publicacion publicacion, {required String? miId}) async {
    if (publicacion.esDe(miId)) throw const PublicacionPropiaFailure();
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    final String id = await _repository.iniciarConversacion(publicacion.id);
    return Conversacion.desdePublicacion(id, publicacion);
  }
}
