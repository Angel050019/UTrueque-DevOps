import '../../../../core/errors/failures.dart';

// ---------------------------------------------------------------------------
// HU-08: Punto de encuentro seguro. Cada fallo lleva el mensaje que ve el
// estudiante. SEGURIDAD: ninguno revela detalles internos.
// Los de conversación cerrada, demasiados mensajes, sin permiso y error del
// servidor son los mismos del chat (chat_failures.dart).
// ---------------------------------------------------------------------------

/// Escenario 5: el lugar no está en el catálogo oficial (o no se eligió).
class PuntoNoPermitidoFailure extends Failure {
  const PuntoNoPermitidoFailure() : super('Solo se permiten zonas seguras dentro de la UTSJR.');
}

/// Escenario 6: horario fuera de lunes a viernes de 7:00 a 20:00, o fuera
/// de los próximos 14 días.
class HorarioNoPermitidoFailure extends Failure {
  const HorarioNoPermitidoFailure()
      : super('Elige un horario de lunes a viernes, de 7:00 a 20:00, dentro de los próximos 14 días.');
}

/// Escenario 7: ya hay un encuentro pendiente o confirmado.
class EncuentroActivoFailure extends Failure {
  const EncuentroActivoFailure()
      : super('Ya hay un punto de encuentro pendiente o confirmado. Cancélalo o recházalo para proponer otro.');
}

/// Escenario 8: nadie responde su propia propuesta.
class EncuentroPropioFailure extends Failure {
  const EncuentroPropioFailure() : super('No puedes responder tu propia propuesta.');
}

/// Escenario 4: una propuesta pendiente solo la cancela quien la hizo.
class CancelarNoPermitidoFailure extends Failure {
  const CancelarNoPermitidoFailure()
      : super('Solo quien hizo la propuesta puede cancelarla. Tú puedes rechazarla.');
}

/// La propuesta ya se aceptó, rechazó o canceló.
class EncuentroNoPendienteFailure extends Failure {
  const EncuentroNoPendienteFailure() : super('Esta propuesta ya fue respondida.');
}

/// El encuentro ya se canceló, se rechazó o ya pasó.
class EncuentroNoActivoFailure extends Failure {
  const EncuentroNoActivoFailure() : super('Este encuentro ya no está activo.');
}

/// Escenario 9: la hora propuesta ya pasó.
class EncuentroVencidoFailure extends Failure {
  const EncuentroVencidoFailure() : super('La hora propuesta ya pasó. Propongan otra.');
}
