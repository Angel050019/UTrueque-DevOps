import 'package:equatable/equatable.dart';

import 'estado_publicacion.dart';
import 'modalidad.dart';

/// Publicación de un artículo tal como está guardada en Supabase.
class Publicacion extends Equatable {
  const Publicacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.categoriaId,
    required this.modalidad,
    required this.estado,
    required this.fotos,
    this.precio,
    this.creadaEn,
    this.portadaUrl,
    this.duenoNombre,
    this.categoriaNombre,
    this.fotosUrls = const [],
    this.duenoFotoUrl,
    this.duenoDivision,
    this.duenoCarrera,
  });

  final String id;

  /// Dueño de la publicación (lo asigna el servidor, no la app).
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final int categoriaId;
  final Modalidad modalidad;

  /// Solo en Venta; `null` en Intercambio y Gratis.
  final double? precio;
  final EstadoPublicacion estado;

  /// Rutas de las fotos dentro del bucket `publicaciones`
  /// (`<id del dueño>/<archivo>`). La primera es la portada.
  final List<String> fotos;
  final DateTime? creadaEn;

  /// Datos extra para mostrar la publicación en el Feed. Solo vienen
  /// cuando se consultan publicaciones (no al crear una).
  ///
  /// URL pública de la primera foto.
  final String? portadaUrl;

  /// Nombre a mostrar del dueño.
  final String? duenoNombre;

  /// Nombre de la categoría.
  final String? categoriaNombre;

  /// HU-04: datos extra para el Detalle. Solo vienen cuando se consulta la
  /// vista `publicaciones_detalle` (Feed y Detalle).
  ///
  /// URL pública de cada foto, en el mismo orden que [fotos].
  final List<String> fotosUrls;

  /// Foto de perfil del dueño (URL pública) o `null` si no tiene.
  final String? duenoFotoUrl;

  /// División y carrera del dueño (datos públicos de su perfil).
  final String? duenoDivision;
  final String? duenoCarrera;

  /// ¿La publicó el estudiante con este [idUsuario]?
  bool esDe(String? idUsuario) => idUsuario != null && idUsuario == usuarioId;

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        titulo,
        descripcion,
        categoriaId,
        modalidad,
        precio,
        estado,
        fotos,
        creadaEn,
        portadaUrl,
        duenoNombre,
        categoriaNombre,
        fotosUrls,
        duenoFotoUrl,
        duenoDivision,
        duenoCarrera,
      ];
}
