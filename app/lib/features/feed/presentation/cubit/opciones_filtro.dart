import 'package:equatable/equatable.dart';

import '../../../perfil/domain/entities/carrera.dart';
import '../../../perfil/domain/entities/division.dart';
import '../../../publicaciones/domain/entities/categoria.dart';

/// Lo que el Feed necesita para dibujar los filtros (HU-05): las categorías
/// (chips), el catálogo División → Carrera (hoja de filtros) y la carrera
/// del perfil del estudiante (chip "Mi carrera").
///
/// Si algo no se pudo cargar (por ejemplo, sin internet) queda vacío y se
/// vuelve a intentar con "Reintentar"; el Feed funciona igual sin ellos.
class OpcionesFiltro extends Equatable {
  const OpcionesFiltro({
    this.categorias = const [],
    this.divisiones = const [],
    this.miCarrera,
    this.perfilLeido = false,
  });

  final List<Categoria> categorias;
  final List<Division> divisiones;

  /// Carrera del perfil del estudiante; `null` si no tiene o no se pudo leer.
  final Carrera? miCarrera;

  /// `true` cuando ya se leyó el perfil (aunque no tenga carrera).
  final bool perfilLeido;

  /// Ya está todo; no hace falta volver a pedir nada.
  bool get completas => categorias.isNotEmpty && divisiones.isNotEmpty && perfilLeido;

  /// Carreras de la división [divisionId] (vacío si no hay división).
  List<Carrera> carrerasDe(int? divisionId) {
    if (divisionId == null) return const [];
    for (final Division division in divisiones) {
      if (division.id == divisionId) return division.carreras;
    }
    return const [];
  }

  String? nombreDivision(int? id) {
    if (id == null) return null;
    for (final Division division in divisiones) {
      if (division.id == id) return division.nombre;
    }
    return null;
  }

  String? nombreCarrera(int? id) {
    if (id == null) return null;
    if (miCarrera?.id == id) return miCarrera?.nombre;
    for (final Division division in divisiones) {
      for (final Carrera carrera in division.carreras) {
        if (carrera.id == id) return carrera.nombre;
      }
    }
    return null;
  }

  OpcionesFiltro copyWith({
    List<Categoria>? categorias,
    List<Division>? divisiones,
    Carrera? miCarrera,
    bool? perfilLeido,
  }) {
    return OpcionesFiltro(
      categorias: categorias ?? this.categorias,
      divisiones: divisiones ?? this.divisiones,
      miCarrera: miCarrera ?? this.miCarrera,
      perfilLeido: perfilLeido ?? this.perfilLeido,
    );
  }

  @override
  List<Object?> get props => [categorias, divisiones, miCarrera, perfilLeido];
}
