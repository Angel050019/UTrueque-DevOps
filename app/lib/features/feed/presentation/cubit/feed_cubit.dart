import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../../publicaciones/domain/entities/publicacion.dart';
import '../../../publicaciones/domain/errors/publicacion_failures.dart';
import '../../../publicaciones/domain/usecases/obtener_feed.dart';
import 'feed_state.dart';

/// Maneja el Feed de publicaciones (HU-04): primera carga, "jalar para
/// actualizar", cargar más al hacer scroll y quitar o actualizar una
/// publicación cuando se ve su detalle.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._obtenerFeed) : super(const FeedCargando());

  final ObtenerFeed _obtenerFeed;

  /// Número de la carga desde el inicio más reciente. Si el estudiante jala
  /// para actualizar mientras se cargaba otra página, la respuesta vieja se
  /// ignora para no mezclar listas.
  int _carga = 0;

  /// Primera carga (y botón "Reintentar"): muestra el indicador de carga.
  Future<void> cargar() async {
    emit(const FeedCargando());
    await _cargarDesdeElInicio();
  }

  /// "Jalar para actualizar" (Escenario 3). Si falla, la lista que ya se
  /// veía se conserva y se muestra el mensaje (Escenario 5).
  Future<void> actualizar() => _cargarDesdeElInicio();

  Future<void> _cargarDesdeElInicio() async {
    final int carga = ++_carga;
    try {
      final PaginaFeed pagina = await _obtenerFeed();
      if (carga != _carga) return;
      emit(_estadoDe(pagina.publicaciones, pagina.siguiente));
    } on Failure catch (falla) {
      if (carga != _carga) return;
      _mostrarFalla(falla);
    } catch (_) {
      if (carga != _carga) return;
      _mostrarFalla(const CargarPublicacionesFailure());
    }
  }

  void _mostrarFalla(Failure falla) {
    final FeedState actual = state;
    if (actual is FeedCargado) {
      emit(actual.copyWith(cargandoMas: false, aviso: () => falla.mensaje));
    } else {
      emit(FeedError(falla));
    }
  }

  /// Siguiente página al llegar al final de la lista (Escenario 2). No hace
  /// nada si ya se está cargando o si ya no hay más.
  Future<void> cargarMas() async {
    final FeedState inicial = state;
    if (inicial is! FeedCargado || inicial.cargandoMas || !inicial.hayMas) return;
    final int carga = _carga;
    emit(inicial.copyWith(cargandoMas: true, errorMas: () => null));
    try {
      final PaginaFeed pagina = await _obtenerFeed(despuesDe: inicial.siguiente);
      final FeedState actual = state;
      if (carga != _carga || actual is! FeedCargado) return;
      // Por si acaso, no se agregan publicaciones que ya están en la lista.
      final Set<String> yaVistas = actual.publicaciones.map((p) => p.id).toSet();
      emit(actual.copyWith(
        publicaciones: [
          ...actual.publicaciones,
          ...pagina.publicaciones.where((p) => !yaVistas.contains(p.id)),
        ],
        siguiente: () => pagina.siguiente,
        cargandoMas: false,
      ));
    } catch (error) {
      final FeedState actual = state;
      if (carga != _carga || actual is! FeedCargado) return;
      final Failure falla = error is Failure ? error : const CargarPublicacionesFailure();
      emit(actual.copyWith(cargandoMas: false, errorMas: () => falla.mensaje));
    }
  }

  /// Se llama al ver el detalle de una publicación (Escenarios 9 y 10):
  /// si se borró ([actualizada] es `null`) o ya se vendió, se quita de la
  /// lista; si cambió (por ejemplo, a Reservado), se actualiza su tarjeta.
  void sincronizar(String id, Publicacion? actualizada) {
    final FeedState actual = state;
    if (actual is! FeedCargado) return;
    final List<Publicacion> lista;
    if (actualizada == null || !actualizada.estado.visibleEnFeed) {
      lista = actual.publicaciones.where((p) => p.id != id).toList(growable: false);
    } else {
      final Publicacion nueva = actualizada;
      lista = actual.publicaciones.map((p) => p.id == id ? nueva : p).toList(growable: false);
    }
    if (lista.isEmpty && !actual.hayMas) {
      emit(const FeedVacio());
    } else {
      emit(actual.copyWith(publicaciones: lista));
    }
  }

  /// La pantalla ya mostró el aviso (SnackBar); se limpia para no repetirlo.
  void avisoMostrado() {
    final FeedState actual = state;
    if (actual is FeedCargado && actual.aviso != null) {
      emit(actual.copyWith(aviso: () => null));
    }
  }

  FeedState _estadoDe(List<Publicacion> publicaciones, CursorFeed? siguiente) {
    if (publicaciones.isEmpty) return const FeedVacio();
    return FeedCargado(publicaciones: publicaciones, siguiente: siguiente);
  }
}
