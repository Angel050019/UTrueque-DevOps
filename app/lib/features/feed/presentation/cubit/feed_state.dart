import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/entities/filtros_feed.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import 'opciones_filtro.dart';

/// Estados del Feed (HU-04 y HU-05).
///
/// Todos llevan los [filtros] puestos y las [opciones] para dibujar los
/// filtros, así el buscador, los chips y "Reintentar" los conservan aunque
/// cambie lo que se ve en la lista.
abstract class FeedState extends Equatable {
  const FeedState({
    this.filtros = const FiltrosFeed(),
    this.opciones = const OpcionesFiltro(),
  });

  final FiltrosFeed filtros;
  final OpcionesFiltro opciones;

  /// El mismo estado con otras [opciones] (cuando terminan de cargar).
  FeedState conOpciones(OpcionesFiltro opciones);

  @override
  List<Object?> get props => [filtros, opciones];
}

/// Cargando la primera página (todavía no hay nada que mostrar).
class FeedCargando extends FeedState {
  const FeedCargando({super.filtros, super.opciones});

  @override
  FeedCargando conOpciones(OpcionesFiltro opciones) =>
      FeedCargando(filtros: filtros, opciones: opciones);
}

/// No hay publicaciones Disponibles ni Reservadas y no hay filtros puestos
/// (HU-04, Escenario 4).
class FeedVacio extends FeedState {
  const FeedVacio({super.filtros, super.opciones});

  @override
  FeedVacio conOpciones(OpcionesFiltro opciones) =>
      FeedVacio(filtros: filtros, opciones: opciones);
}

/// Hay filtros puestos y ninguna publicación los cumple (HU-05,
/// Escenario 6). La pantalla muestra [mensaje] y "Limpiar filtros".
class FeedSinResultados extends FeedState {
  const FeedSinResultados({super.filtros, super.opciones});

  static const String mensaje = 'No se encontraron artículos que coincidan con tu búsqueda.';

  @override
  FeedSinResultados conOpciones(OpcionesFiltro opciones) =>
      FeedSinResultados(filtros: filtros, opciones: opciones);
}

/// Falló la primera carga y no hay nada en pantalla (HU-04, Escenarios 5 y
/// 6; HU-05, Escenarios 8 y 9). La pantalla muestra [mensaje] y el botón
/// "Reintentar", que repite la búsqueda con los mismos filtros.
class FeedError extends FeedState {
  const FeedError(this.failure, {super.filtros, super.opciones});

  final Failure failure;

  String get mensaje => failure.mensaje;

  bool get sinConexion => failure is SinConexionFailure;

  @override
  FeedError conOpciones(OpcionesFiltro opciones) =>
      FeedError(failure, filtros: filtros, opciones: opciones);

  @override
  List<Object?> get props => [failure, ...super.props];
}

/// Hay publicaciones en pantalla.
class FeedCargado extends FeedState {
  const FeedCargado({
    required this.publicaciones,
    this.siguiente,
    this.cargandoMas = false,
    this.errorMas,
    this.aviso,
    super.filtros,
    super.opciones,
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
  /// actualizar" falla: la lista que ya se veía se conserva.
  final String? aviso;

  bool get hayMas => siguiente != null;

  FeedCargado copyWith({
    List<Publicacion>? publicaciones,
    CursorFeed? Function()? siguiente,
    bool? cargandoMas,
    String? Function()? errorMas,
    String? Function()? aviso,
    OpcionesFiltro? opciones,
  }) {
    return FeedCargado(
      publicaciones: publicaciones ?? this.publicaciones,
      siguiente: siguiente != null ? siguiente() : this.siguiente,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      errorMas: errorMas != null ? errorMas() : this.errorMas,
      aviso: aviso != null ? aviso() : this.aviso,
      filtros: filtros,
      opciones: opciones ?? this.opciones,
    );
  }

  @override
  FeedCargado conOpciones(OpcionesFiltro opciones) => copyWith(opciones: opciones);

  @override
  List<Object?> get props => [
        publicaciones,
        siguiente,
        cargandoMas,
        errorMas,
        aviso,
        ...super.props,
      ];
}
