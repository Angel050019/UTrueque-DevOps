import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/pagina_feed.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: una página de "Mis publicaciones" (HU-06, Escenarios 1 y 2).
///
/// Solo las publicaciones del estudiante con sesión (el servidor toma al
/// dueño de la sesión, no de un parámetro). [finalizadas] = false trae las
/// Activas (Disponibles y Reservadas); true trae el historial (Vendidas).
/// Con [despuesDe] trae la página siguiente, igual que el Feed.
class ObtenerMisPublicaciones {
  ObtenerMisPublicaciones(this._repository, this._networkInfo);

  /// Publicaciones por página (la base entrega como máximo 50).
  static const int publicacionesPorPagina = 20;

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<PaginaFeed> call({bool finalizadas = false, CursorFeed? despuesDe}) async {
    // Escenario 12: sin internet no se envía nada a Supabase.
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerMisPublicaciones(
      finalizadas: finalizadas,
      despuesDe: despuesDe,
      limite: publicacionesPorPagina,
    );
  }
}
