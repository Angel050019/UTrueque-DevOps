import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/conversacion.dart';
import '../entities/mensaje.dart';
import '../errors/chat_failures.dart';
import '../repositories/chat_repository.dart';
import '../validators/mensaje_validator.dart';

/// Caso de uso: enviar un mensaje (HU-07, Escenarios 3, 10, 11, 13 y 14).
///
/// 1. Una conversación cerrada (publicación Vendida o borrada) no acepta
///    mensajes.
/// 2. Valida el texto sin tocar la red (Escenario 10).
/// 3. Revisa la conexión (Escenario 14).
/// 4. Envía el texto sin espacios de sobra. El servidor vuelve a revisar
///    todo (estado, caracteres y límite contra el spam).
class EnviarMensaje {
  EnviarMensaje(this._repository, this._networkInfo, {MensajeValidator validador = const MensajeValidator()})
      : _validador = validador;

  final ChatRepository _repository;
  final NetworkInfo _networkInfo;
  final MensajeValidator _validador;

  Future<Mensaje> call(Conversacion conversacion, String texto) async {
    if (!conversacion.aceptaMensajes) throw const ConversacionCerradaFailure();
    final String? error = _validador.validar(texto);
    if (error != null) throw MensajeInvalidoFailure(error);
    if (!await _networkInfo.estaConectado) throw const SinConexionFailure();
    return _repository.enviarMensaje(conversacion.id, texto.trim());
  }
}
