import '../entities/resumen_reputacion.dart';
import '../entities/trato.dart';

/// Contrato de la reputación (HU-09). La implementación habla con Supabase;
/// el dominio no sabe nada de HTTP.
abstract class ReputacionRepository {
  /// Quienes le escribieron al vendedor por su publicación (Escenario 1).
  Future<List<CompradorPosible>> compradoresPosibles(String publicacionId);

  /// Marca la publicación como Vendida. Con [conversacionId] registra el
  /// trato y devuelve su id; sin él ("fuera de UTrueque") devuelve `null`.
  Future<String?> marcarVendida(String publicacionId, {String? conversacionId});

  /// Mis tratos de los últimos 14 días que todavía no califico.
  Future<List<TratoPorCalificar>> tratosPorCalificar();

  /// Califica al otro participante del trato. El servidor toma quién
  /// califica de la sesión y a quién, de la venta.
  Future<void> calificar({required String ventaId, required int estrellas, String? comentario});

  /// Cuántas calificaciones de cada estrella tiene [usuarioId].
  Future<ResumenReputacion> resumen(String usuarioId);

  /// Las calificaciones que recibí, de [limite] en [limite]. Con
  /// [despuesDe] se pide la página siguiente.
  Future<PaginaCalificaciones> recibidas({CalificacionRecibida? despuesDe, int limite = 20});
}
