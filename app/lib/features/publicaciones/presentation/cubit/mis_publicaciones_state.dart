import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/pagina_feed.dart';
import '../../domain/entities/publicacion.dart';

/// Estados de "Mis publicaciones" (HU-06). Todos saben qué pestaña se ve:
/// [finalizadas] = false → Activas (Disponibles y Reservadas);
/// true → Finalizadas (Vendidas).
abstract class MisPublicacionesState extends Equatable {
  const MisPublicacionesState({this.finalizadas = false});

  final bool finalizadas;

  @override
  List<Object?> get props => [finalizadas];
}

class MisPublicacionesCargando extends MisPublicacionesState {
  const MisPublicacionesCargando({super.finalizadas});
}

/// La pestaña no tiene publicaciones (Escenarios 2 y 11).
class MisPublicacionesVacio extends MisPublicacionesState {
  const MisPublicacionesVacio({super.finalizadas});

  String get mensaje => finalizadas
      ? 'Aún no tienes publicaciones finalizadas.'
      : 'Aún no tienes publicaciones activas.';
}

/// No se pudo cargar y no hay nada en pantalla (Escenarios 12 y 13).
class MisPublicacionesError extends MisPublicacionesState {
  const MisPublicacionesError(this.failure, {super.finalizadas});

  final Failure failure;

  String get mensaje => failure.mensaje;

  bool get sinConexion => failure is SinConexionFailure;

  @override
  List<Object?> get props => [finalizadas, failure];
}

/// La lista ya cargó (Escenarios 1 y 2).
class MisPublicacionesCargado extends MisPublicacionesState {
  const MisPublicacionesCargado({
    required this.publicaciones,
    this.siguiente,
    this.cargandoMas = false,
    this.errorMas,
    this.aviso,
    super.finalizadas,
  });

  final List<Publicacion> publicaciones;

  /// Cursor de la siguiente página; `null` si ya no hay más.
  final CursorFeed? siguiente;

  /// Se está pidiendo la siguiente página (spinner al final de la lista).
  final bool cargandoMas;

  /// No se pudo cargar la siguiente página (mensaje + "Reintentar").
  final String? errorMas;

  /// Mensaje de un solo uso (SnackBar), por ejemplo si falla "jalar para
  /// actualizar": la lista que ya se veía se conserva.
  final String? aviso;

  bool get hayMas => siguiente != null;

  MisPublicacionesCargado copyWith({
    List<Publicacion>? publicaciones,
    CursorFeed? Function()? siguiente,
    bool? cargandoMas,
    String? Function()? errorMas,
    String? Function()? aviso,
  }) {
    return MisPublicacionesCargado(
      publicaciones: publicaciones ?? this.publicaciones,
      siguiente: siguiente != null ? siguiente() : this.siguiente,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      errorMas: errorMas != null ? errorMas() : this.errorMas,
      aviso: aviso != null ? aviso() : this.aviso,
      finalizadas: finalizadas,
    );
  }

  @override
  List<Object?> get props => [finalizadas, publicaciones, siguiente, cargandoMas, errorMas, aviso];
}
