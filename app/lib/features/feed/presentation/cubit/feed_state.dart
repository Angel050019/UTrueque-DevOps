import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';

/// Estados del Feed (HU-04).
abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => const [];
}

/// Cargando la primera página (todavía no hay nada que mostrar).
class FeedCargando extends FeedState {
  const FeedCargando();
}

/// No hay publicaciones Disponibles ni Reservadas (Escenario 4).
class FeedVacio extends FeedState {
  const FeedVacio();
}

/// Falló la primera carga y no hay nada en pantalla (Escenarios 5 y 6).
/// La pantalla muestra [mensaje] y el botón "Reintentar".
class FeedError extends FeedState {
  const FeedError(this.failure);

  final Failure failure;

  String get mensaje => failure.mensaje;

  bool get sinConexion => failure is SinConexionFailure;

  @override
  List<Object?> get props => [failure];
}

/// Hay publicaciones en pantalla.
class FeedCargado extends FeedState {
  const FeedCargado({
    required this.publicaciones,
    this.siguiente,
    this.cargandoMas = false,
    this.errorMas,
    this.aviso,
  });

  final List<Publicacion> publicaciones;

  /// Cursor para pedir la siguiente página; `null` si ya no hay más.
  final CursorFeed? siguiente;

  /// Se está pidiendo la siguiente página (spinner al final de la lista).
  final bool cargandoMas;

  /// No se pudo cargar la siguiente página; al final de la lista se muestra
  /// este mensaje con un botón para reintentar.
  final String? errorMas;

  /// Mensaje de un solo uso (SnackBar), por ejemplo cuando "jalar para
  /// actualizar" falla: la lista que ya se veía se conserva (Escenario 5).
  final String? aviso;

  bool get hayMas => siguiente != null;

  FeedCargado copyWith({
    List<Publicacion>? publicaciones,
    CursorFeed? Function()? siguiente,
    bool? cargandoMas,
    String? Function()? errorMas,
    String? Function()? aviso,
  }) {
    return FeedCargado(
      publicaciones: publicaciones ?? this.publicaciones,
      siguiente: siguiente != null ? siguiente() : this.siguiente,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      errorMas: errorMas != null ? errorMas() : this.errorMas,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }

  @override
  List<Object?> get props => [publicaciones, siguiente, cargandoMas, errorMas, aviso];
}
