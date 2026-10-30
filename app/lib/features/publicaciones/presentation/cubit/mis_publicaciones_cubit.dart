import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/pagina_feed.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../../domain/usecases/obtener_mis_publicaciones.dart';
import 'mis_publicaciones_state.dart';

/// Maneja la pantalla "Mis publicaciones" (HU-06): pestañas Activas y
/// Finalizadas, scroll infinito, "jalar para actualizar" y la
/// sincronización cuando una publicación cambia (Escenario 14).
class MisPublicacionesCubit extends Cubit<MisPublicacionesState> {
  MisPublicacionesCubit(this._obtener) : super(const MisPublicacionesCargando());

  final ObtenerMisPublicaciones _obtener;

  /// Número de la carga actual. Si el estudiante cambia de pestaña o
  /// actualiza mientras llegaba una respuesta vieja, esa respuesta se ignora.
  int _carga = 0;

  /// Primera carga de la pestaña actual (también es "Reintentar").
  Future<void> cargar() {
    final int carga = ++_carga;
    _emitir(MisPublicacionesCargando(finalizadas: state.finalizadas));
    return _cargarDesdeElInicio(carga);
  }

  /// "Jalar para actualizar": recarga sin quitar la lista que ya se ve.
  Future<void> actualizar() => _cargarDesdeElInicio(++_carga);

  /// Cambia entre Activas (false) y Finalizadas (true) (Escenario 2).
  Future<void> cambiarPestana({required bool finalizadas}) async {
    if (finalizadas == state.finalizadas && state is! MisPublicacionesError) return;
    final int carga = ++_carga;
    _emitir(MisPublicacionesCargando(finalizadas: finalizadas));
    await _cargarDesdeElInicio(carga);
  }

  Future<void> _cargarDesdeElInicio(int carga) async {
    final bool finalizadas = state.finalizadas;
    try {
      final PaginaFeed pagina = await _obtener(finalizadas: finalizadas);
      if (carga != _carga) return;
      _emitir(pagina.publicaciones.isEmpty
          ? MisPublicacionesVacio(finalizadas: finalizadas)
          : MisPublicacionesCargado(
              publicaciones: pagina.publicaciones,
              siguiente: pagina.siguiente,
              finalizadas: finalizadas,
            ));
    } catch (error) {
      if (carga != _carga) return;
      final Failure falla = error is Failure ? error : const CargarMisPublicacionesFailure();
      final MisPublicacionesState actual = state;
      if (actual is MisPublicacionesCargado) {
        // Escenario 12: la lista que ya se veía se conserva.
        _emitir(actual.copyWith(aviso: () => falla.mensaje));
      } else {
        _emitir(MisPublicacionesError(falla, finalizadas: finalizadas));
      }
    }
  }

  /// Siguiente página al llegar al final de la lista (Escenario 1).
  Future<void> cargarMas() async {
    final MisPublicacionesState inicial = state;
    if (inicial is! MisPublicacionesCargado || inicial.cargandoMas || !inicial.hayMas) return;
    final int carga = _carga;
    _emitir(inicial.copyWith(cargandoMas: true, errorMas: () => null));
    try {
      final PaginaFeed pagina =
          await _obtener(finalizadas: inicial.finalizadas, despuesDe: inicial.siguiente);
      final MisPublicacionesState actual = state;
      if (carga != _carga || actual is! MisPublicacionesCargado) return;
      final Set<String> yaVistas = actual.publicaciones.map((p) => p.id).toSet();
      _emitir(actual.copyWith(
        publicaciones: [
          ...actual.publicaciones,
          ...pagina.publicaciones.where((p) => !yaVistas.contains(p.id)),
        ],
        siguiente: () => pagina.siguiente,
        cargandoMas: false,
      ));
    } catch (error) {
      final MisPublicacionesState actual = state;
      if (carga != _carga || actual is! MisPublicacionesCargado) return;
      final Failure falla = error is Failure ? error : const CargarMisPublicacionesFailure();
      _emitir(actual.copyWith(cargandoMas: false, errorMas: () => falla.mensaje));
    }
  }

  /// Escenario 14: una publicación cambió ([actualizada]) o se borró
  /// (`null`). Si ya no pertenece a esta pestaña (por ejemplo, se vendió y
  /// estamos en Activas) se quita; si sigue, se reemplaza.
  void sincronizar(String id, Publicacion? actualizada) {
    final MisPublicacionesState actual = state;
    if (actual is! MisPublicacionesCargado) {
      // Una publicación que acaba de llegar a esta pestaña (por ejemplo,
      // una recién vendida con Finalizadas vacía): se vuelve a cargar.
      if (actual is MisPublicacionesVacio &&
          actualizada != null &&
          actualizada.estado.esFinal == actual.finalizadas) {
        actualizar();
      }
      return;
    }
    final bool sigueAqui = actualizada != null && actualizada.estado.esFinal == actual.finalizadas;
    final bool estaba = actual.publicaciones.any((p) => p.id == id);
    if (!estaba) {
      // Llegó a esta pestaña desde la otra: se recarga para ponerla en su lugar.
      if (sigueAqui) actualizar();
      return;
    }
    final List<Publicacion> lista;
    if (actualizada != null && sigueAqui) {
      final Publicacion nueva = actualizada;
      lista = actual.publicaciones.map((p) => p.id == id ? nueva : p).toList(growable: false);
    } else {
      lista = actual.publicaciones.where((p) => p.id != id).toList(growable: false);
    }
    if (lista.isEmpty && !actual.hayMas) {
      _emitir(MisPublicacionesVacio(finalizadas: actual.finalizadas));
    } else {
      _emitir(actual.copyWith(publicaciones: lista));
    }
  }

  /// La pantalla ya mostró el aviso (SnackBar); se limpia para no repetirlo.
  void avisoMostrado() {
    final MisPublicacionesState actual = state;
    if (actual is MisPublicacionesCargado && actual.aviso != null) {
      _emitir(actual.copyWith(aviso: () => null));
    }
  }

  void _emitir(MisPublicacionesState nuevo) {
    if (!isClosed) emit(nuevo);
  }
}
