import 'package:equatable/equatable.dart';

/// Carrera del catálogo académico. Siempre pertenece a una [divisionId].
class Carrera extends Equatable {
  const Carrera({
    required this.id,
    required this.divisionId,
    required this.nombre,
  });

  final int id;
  final int divisionId;
  final String nombre;

  @override
  List<Object?> get props => [id, divisionId, nombre];
}
