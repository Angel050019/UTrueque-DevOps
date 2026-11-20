import 'package:equatable/equatable.dart';

/// Cuántas calificaciones de cada estrella tiene un estudiante (HU-09).
///
/// Es lo único que el servidor da de la reputación de otro estudiante:
/// nunca quién lo calificó ni sus comentarios. El promedio lo calcula la
/// app con una estrategia (ver `estrategias_reputacion.dart`).
class ResumenReputacion extends Equatable {
  const ResumenReputacion({
    required this.usuarioId,
    this.una = 0,
    this.dos = 0,
    this.tres = 0,
    this.cuatro = 0,
    this.cinco = 0,
  });

  /// Un estudiante sin calificaciones.
  const ResumenReputacion.vacio(this.usuarioId)
      : una = 0,
        dos = 0,
        tres = 0,
        cuatro = 0,
        cinco = 0;

  final String usuarioId;
  final int una;
  final int dos;
  final int tres;
  final int cuatro;
  final int cinco;

  /// Total de calificaciones.
  int get total => una + dos + tres + cuatro + cinco;

  /// Suma de todas las estrellas.
  int get sumaEstrellas => una + dos * 2 + tres * 3 + cuatro * 4 + cinco * 5;

  /// Escenario 7: todavía nadie lo ha calificado.
  bool get sinCalificaciones => total == 0;

  /// Cuántas calificaciones de [estrellas] (1 a 5) tiene; 0 si no es válido.
  int de(int estrellas) => switch (estrellas) {
        1 => una,
        2 => dos,
        3 => tres,
        4 => cuatro,
        5 => cinco,
        _ => 0,
      };

  @override
  List<Object?> get props => [usuarioId, una, dos, tres, cuatro, cinco];
}
