import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/filtros_feed.dart';
import '../entities/pagina_feed.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: una página del Feed con búsqueda y filtros (HU-04 y HU-05).
///
/// Publicaciones Disponibles y Reservadas, de la más nueva a la más vieja,
/// que cumplen todos los [filtros] (sin filtros es el Feed completo de
/// HU-04). Sin [despuesDe] trae la primera página; con el cursor de la
/// página anterior trae la siguiente, con los mismos filtros, sin repetir
/// ni saltarse ninguna aunque alguien publique mientras se hace scroll.
class BuscarPublicaciones {
  BuscarPublicaciones(this._repository, this._networkInfo);

  /// Publicaciones por página (la base entrega como máximo 50).
  static const int publicacionesPorPagina = 20;

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<PaginaFeed> call({
    FiltrosFeed filtros = const FiltrosFeed(),
    CursorFeed? despuesDe,
  }) async {
    // HU-05, Escenario 8: sin internet no se envía nada a Supabase.
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.buscarPublicaciones(
      filtros: filtros,
      despuesDe: despuesDe,
      limite: publicacionesPorPagina,
    );
  }
}
