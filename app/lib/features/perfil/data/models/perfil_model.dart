import '../../domain/entities/perfil.dart';

/// Modelo de datos del perfil: sabe leerse desde una fila de `usuarios`
/// con los nombres de división y carrera embebidos (ver [columnasSelect]).
class PerfilModel extends Perfil {
  const PerfilModel({
    required super.id,
    super.nombreMostrar,
    super.divisionId,
    super.divisionNombre,
    super.carreraId,
    super.carreraNombre,
    super.fotoUrl,
    super.perfilCompleto,
  });

  /// Columnas que se piden a Supabase. Los nombres de división y carrera se
  /// traen con un "join" por llave foránea (alias division_info y
  /// carrera_info para no chocar con las columnas viejas de texto).
  static const String columnasSelect = 'id, nombre_mostrar, division_id, carrera_id, '
      'foto_url, perfil_completo, '
      'division_info:divisiones!usuarios_division_id_fkey(nombre), '
      'carrera_info:carreras!usuarios_carrera_division_fkey(nombre)';

  factory PerfilModel.fromMap(Map<String, dynamic> mapa) {
    final Map<String, dynamic>? division = mapa['division_info'] as Map<String, dynamic>?;
    final Map<String, dynamic>? carrera = mapa['carrera_info'] as Map<String, dynamic>?;
    return PerfilModel(
      id: mapa['id'] as String,
      nombreMostrar: mapa['nombre_mostrar'] as String?,
      divisionId: (mapa['division_id'] as num?)?.toInt(),
      divisionNombre: division?['nombre'] as String?,
      carreraId: (mapa['carrera_id'] as num?)?.toInt(),
      carreraNombre: carrera?['nombre'] as String?,
      fotoUrl: mapa['foto_url'] as String?,
      perfilCompleto: mapa['perfil_completo'] as bool? ?? false,
    );
  }
}
