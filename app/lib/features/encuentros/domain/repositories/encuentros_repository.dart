import '../entities/encuentro.dart';
import '../entities/punto_encuentro.dart';
import '../entities/solicitud_encuentro.dart';

/// Contrato de los puntos de encuentro (HU-08). La implementación habla con
/// Supabase; el dominio no sabe nada de HTTP.
abstract class EncuentrosRepository {
  /// El catálogo oficial de lugares activos, en orden.
  Future<List<PuntoEncuentro>> obtenerPuntos();

  /// Los encuentros de una conversación, el más reciente primero.
  Future<List<Encuentro>> obtenerEncuentros(String conversacionId);

  /// Envía la solicitud fabricada por un creador. El servidor revisa todas
  /// las reglas y crea la tarjeta en el chat.
  Future<void> enviar(SolicitudEncuentro solicitud);
}
