import '../../../../core/errors/failures.dart';

// ---------------------------------------------------------------------------
// HU-07: Chat directo. Cada fallo lleva el mensaje que ve el estudiante.
// SEGURIDAD: ninguno revela detalles internos (tablas, reglas, direcciones).
// ---------------------------------------------------------------------------

/// Escenario 4: no se puede iniciar un chat sobre una publicación propia.
class PublicacionPropiaFailure extends Failure {
  const PublicacionPropiaFailure() : super('No puedes escribirte en tu propia publicación.');
}

/// Escenario 5: la publicación está Reservada o Vendida y no hay una
/// conversación previa.
class PublicacionNoDisponibleFailure extends Failure {
  const PublicacionNoDisponibleFailure()
      : super('Esta publicación ya no acepta nuevos mensajes.');
}

/// Escenario 6: el perfil no está completo.
class PerfilIncompletoChatFailure extends Failure {
  const PerfilIncompletoChatFailure()
      : super('Completa tu perfil para poder contactar al vendedor.');
}

/// Escenario 11: la publicación se vendió o se borró.
class ConversacionCerradaFailure extends Failure {
  const ConversacionCerradaFailure()
      : super('Esta publicación ya no está disponible. Puedes leer la conversación, '
            'pero ya no enviar mensajes.');
}

/// Escenario 13: más de 20 mensajes en un minuto.
class DemasiadosMensajesFailure extends Failure {
  const DemasiadosMensajesFailure() : super('Estás enviando muchos mensajes. Espera un momento.');
}

/// Escenario 10: el mensaje está vacío, es muy largo o tiene caracteres no
/// permitidos.
class MensajeInvalidoFailure extends Failure {
  const MensajeInvalidoFailure(super.mensaje);
}

/// Escenario 12: la conversación no es del estudiante.
class ChatSinPermisoFailure extends Failure {
  const ChatSinPermisoFailure() : super('No tienes acceso a esta conversación.');
}

/// Escenario 15: error del servidor.
class ChatServidorFailure extends ServidorFailure {
  const ChatServidorFailure() : super('No pudimos completar la acción. Inténtalo de nuevo.');
}
