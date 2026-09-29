import '../../domain/entities/carrera.dart';
import '../../domain/entities/division.dart';

/// Modelo de datos de una división con sus carreras embebidas.
class DivisionModel extends Division {
  const DivisionModel({
    required super.id,
    required super.nombre,
    super.carreras,
  });

  /// Columnas que se piden a Supabase para el catálogo.
  static const String columnasSelect =
      'id, nombre, orden, carreras(id, division_id, nombre, activo, orden)';

  /// Construye la división a partir de una fila de `divisiones`.
  /// Descarta carreras inactivas y las ordena por `orden` y nombre.
  factory DivisionModel.fromMap(Map<String, dynamic> mapa) {
    final List<Map<String, dynamic>> filasCarreras =
        ((mapa['carreras'] as List<dynamic>?) ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()
            .where((fila) => fila['activo'] as bool? ?? true)
            .toList()
          ..sort((a, b) {
            final int porOrden =
                ((a['orden'] as num?) ?? 0).compareTo((b['orden'] as num?) ?? 0);
            if (porOrden != 0) return porOrden;
            return (a['nombre'] as String).compareTo(b['nombre'] as String);
          });

    return DivisionModel(
      id: (mapa['id'] as num).toInt(),
      nombre: mapa['nombre'] as String,
      carreras: filasCarreras
          .map(
            (fila) => Carrera(
              id: (fila['id'] as num).toInt(),
              divisionId: (fila['division_id'] as num).toInt(),
              nombre: fila['nombre'] as String,
            ),
          )
          .toList(growable: false),
    );
  }
}
