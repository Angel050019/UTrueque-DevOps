import 'package:equatable/equatable.dart';

import 'mensaje.dart';

/// Lo que avisa el tiempo real a sus observadores (HU-07, patrón Observer).
sealed class AvisoChat extends Equatable {
  const AvisoChat();
}

/// Llegó un mensaje nuevo de una de MIS conversaciones (Escenario 3).
class MensajeRecibido extends AvisoChat {
  const MensajeRecibido(this.mensaje);

  final Mensaje mensaje;

  @override
  List<Object?> get props => [mensaje];
}

/// La conexión en tiempo real se abrió (o se recuperó después de perder
/// la red). Los observadores vuelven a pedir lo último para no perderse
/// ningún mensaje que llegó mientras no estaban conectados.
class ChatConectado extends AvisoChat {
  const ChatConectado();

  @override
  List<Object?> get props => const [];
}
