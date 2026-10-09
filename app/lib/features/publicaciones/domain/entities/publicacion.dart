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

  @override
  List<Object?> get props =>
      [id, usuarioId, titulo, descripcion, categoriaId, modalidad, precio, estado, fotos, creadaEn];
}
