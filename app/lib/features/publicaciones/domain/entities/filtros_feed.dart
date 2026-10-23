import 'package:equatable/equatable.dart';

/// Filtros del Feed (HU-05): texto del buscador, categoría y la división y
/// carrera del dueño de la publicación. Todos son opcionales y se combinan
/// (la publicación debe cumplir todos los que estén puestos).
///
/// Es un objeto de valor: nunca cambia. Cada método regresa unos filtros
/// nuevos, así el Cubit puede comparar "antes" y "después" con `==`.
class FiltrosFeed extends Equatable {
  const FiltrosFeed({
    this.texto = '',
    this.categoriaId,
    this.divisionId,
    this.carreraId,
  });

  /// Máximo de caracteres que se mandan al buscar (la base también lo
  /// recorta). SEGURIDAD: nadie manda un texto gigante.
  static const int maximoCaracteres = 100;

  /// Texto ya limpio (ver [normalizarTexto]). Vacío = sin búsqueda.
  final String texto;
  final int? categoriaId;
  final int? divisionId;
  final int? carreraId;

  /// Quita espacios al inicio y al final, junta los espacios repetidos y
  /// recorta a [maximoCaracteres]. "  calculadora   hp " → "calculadora hp".
  static String normalizarTexto(String texto) {
    final String limpio = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.length <= maximoCaracteres) return limpio;
    int corte = maximoCaracteres;
    // No partir un emoji u otro carácter que ocupa dos unidades.
    final int unidad = limpio.codeUnitAt(corte - 1);
    if (unidad >= 0xD800 && unidad <= 0xDBFF) corte--;
    return limpio.substring(0, corte).trimRight();
  }

  bool get tieneTexto => texto.isNotEmpty;

  /// Hay al menos un filtro puesto (texto, categoría, división o carrera).
  bool get hayFiltros =>
      tieneTexto || categoriaId != null || divisionId != null || carreraId != null;

  /// Filtra por la división o la carrera del dueño.
  bool get filtraPorDivisionOCarrera => divisionId != null || carreraId != null;

  FiltrosFeed conTexto(String nuevoTexto) => FiltrosFeed(
        texto: normalizarTexto(nuevoTexto),
        categoriaId: categoriaId,
        divisionId: divisionId,
        carreraId: carreraId,
      );

  /// `null` = todas las categorías ("Todo").
  FiltrosFeed conCategoria(int? nuevaCategoriaId) => FiltrosFeed(
        texto: texto,
        categoriaId: nuevaCategoriaId,
        divisionId: divisionId,
        carreraId: carreraId,
      );

  /// División y carrera juntas, porque la carrera depende de la división.
  /// `null` en ambas = todas las divisiones y carreras.
  FiltrosFeed conDivisionYCarrera({int? divisionId, int? carreraId}) => FiltrosFeed(
        texto: texto,
        categoriaId: categoriaId,
        divisionId: divisionId,
        carreraId: carreraId,
      );

  @override
  List<Object?> get props => [texto, categoriaId, divisionId, carreraId];
}
