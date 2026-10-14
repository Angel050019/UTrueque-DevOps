import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/pagina_feed.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: una página del Feed (HU-04).
///
/// Publicaciones Disponibles y Reservadas, de la más nueva a la más vieja.
/// Sin [despuesDe] trae la primera página; con el cursor de la página
/// anterior trae la siguiente, sin repetir ni saltarse ninguna aunque
/// alguien publique mientras se hace scroll.
class ObtenerFeed {
  ObtenerFeed(this._repository, this._networkInfo);

  /// Publicaciones por página (la base entrega como máximo 50).
  static const int publicacionesPorPagina = 20;

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<PaginaFeed> call({CursorFeed? despuesDe}) async {
    // HU-04, Escenario 5: sin internet no se envía nada a Supabase.
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerFeed(despuesDe: despuesDe, limite: publicacionesPorPagina);
  }
}
