import 'package:equatable/equatable.dart';

import 'carrera.dart';

/// División académica de la UTSJR (la universidad se organiza en
/// División → Carrera). Trae sus carreras para llenar el segundo selector.
class Division extends Equatable {
  const Division({
    required this.id,
    required this.nombre,
    this.carreras = const [],
  });

  final int id;
  final String nombre;
  final List<Carrera> carreras;

  /// `true` si [carrera] pertenece a esta división.
  bool contieneCarrera(Carrera carrera) =>
      carrera.divisionId == id && carreras.any((c) => c.id == carrera.id);

  @override
  List<Object?> get props => [id, nombre, carreras];
}
