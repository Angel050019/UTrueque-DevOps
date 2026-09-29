import 'package:equatable/equatable.dart';

/// Perfil académico público de un estudiante (HU-02).
/// Es lo que otros estudiantes ven en publicaciones y chat.
class Perfil extends Equatable {
  const Perfil({
    required this.id,
    this.nombreMostrar,
    this.divisionId,
    this.divisionNombre,
    this.carreraId,
    this.carreraNombre,
    this.fotoUrl,
    this.perfilCompleto = false,
  });

  final String id;
  final String? nombreMostrar;
  final int? divisionId;
  final String? divisionNombre;
  final int? carreraId;
  final String? carreraNombre;
  final String? fotoUrl;

  /// Lo calcula la base de datos: `true` cuando hay nombre, división y
  /// carrera. Decide si después del login se va a "Completar perfil".
  final bool perfilCompleto;

  bool get tieneFoto => fotoUrl != null && fotoUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        nombreMostrar,
        divisionId,
        divisionNombre,
        carreraId,
        carreraNombre,
        fotoUrl,
        perfilCompleto,
      ];
}
