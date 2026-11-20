import '../../../../core/errors/failures.dart';

// ---------------------------------------------------------------------------
// HU-09: Reputación. Cada fallo lleva el mensaje que ve el estudiante.
// SEGURIDAD: ninguno revela detalles internos (tablas, reglas, direcciones).
// ---------------------------------------------------------------------------

/// Escenario 11: el comprador elegido no le escribió por esa publicación.
class CompradorNoValidoFailure extends Failure {
  const CompradorNoValidoFailure() : super('Elige a alguien que te escribió por esta publicación.');
}

/// Escenario 9: ya calificó ese trato.
class CalificacionDuplicadaFailure extends Failure {
  const CalificacionDuplicadaFailure() : super('Ya calificaste este trato.');
}

/// Escenario 10: pasaron más de 14 días desde la venta.
class PlazoVencidoFailure extends Failure {
  const PlazoVencidoFailure() : super('Ya pasaron los 14 días para calificar este trato.');
}

/// Escenario 12: estrellas o comentario no válidos.
class CalificacionInvalidaFailure extends Failure {
  const CalificacionInvalidaFailure(super.mensaje);
}

/// Escenario 11: el trato o la publicación no son del estudiante.
class ReputacionSinPermisoFailure extends Failure {
  const ReputacionSinPermisoFailure() : super('No tienes acceso a este trato.');
}

/// Escenario 14: error del servidor.
class ReputacionServidorFailure extends ServidorFailure {
  const ReputacionServidorFailure() : super('No pudimos completar la acción. Inténtalo de nuevo.');
}
