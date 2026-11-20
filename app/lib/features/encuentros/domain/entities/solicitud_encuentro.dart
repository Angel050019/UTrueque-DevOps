import 'package:equatable/equatable.dart';

/// HU-08, patrón Factory Method: los PRODUCTOS.
///
/// Una solicitud es lo que el estudiante le pide al servidor sobre un
/// encuentro. Cada clase lleva solo los datos que necesita. Las fabrican los
/// creadores de `creadores_solicitud.dart`, que antes revisan las reglas.
sealed class SolicitudEncuentro extends Equatable {
  const SolicitudEncuentro();
}

/// Proponer un lugar del catálogo con día y hora (Escenario 1).
class PropuestaEncuentro extends SolicitudEncuentro {
  const PropuestaEncuentro({required this.conversacionId, required this.puntoId, required this.fechaHora});

  final String conversacionId;
  final String puntoId;
  final DateTime fechaHora;

  @override
  List<Object?> get props => [conversacionId, puntoId, fechaHora];
}

/// Aceptar ([acepta] = true) o rechazar una propuesta (Escenarios 2 y 3).
class RespuestaEncuentro extends SolicitudEncuentro {
  const RespuestaEncuentro({required this.encuentroId, required this.acepta});

  final String encuentroId;
  final bool acepta;

  @override
  List<Object?> get props => [encuentroId, acepta];
}

/// Cancelar una propuesta propia o un encuentro confirmado (Escenario 4).
class CancelacionEncuentro extends SolicitudEncuentro {
  const CancelacionEncuentro({required this.encuentroId});

  final String encuentroId;

  @override
  List<Object?> get props => [encuentroId];
}
