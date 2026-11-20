import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../entities/aviso_chat.dart';
import '../entities/conversacion.dart';
import '../entities/mensaje.dart';
import '../entities/pagina_mensajes.dart';

/// Contrato del chat (HU-07). La implementación habla con Supabase; el
/// dominio no sabe nada de HTTP ni de WebSockets.
abstract class ChatRepository {
  /// Abre (o crea) la conversación sobre la publicación [publicacionId] y
  /// devuelve su id. El servidor revisa todas las reglas.
  Future<String> iniciarConversacion(String publicacionId);

  /// Bandeja: las conversaciones del estudiante, la más reciente primero.
  Future<List<Conversacion>> obtenerConversaciones();

  /// Una página de mensajes, los más nuevos primero.
  Future<PaginaMensajes> obtenerMensajes(String conversacionId, {CursorFeed? antesDe, required int limite});

  /// Envía [texto] y devuelve el mensaje guardado.
  Future<Mensaje> enviarMensaje(String conversacionId, String texto);

  /// Marca la conversación como leída por el estudiante con sesión.
  Future<void> marcarLeida(String conversacionId);

  /// Cuántas conversaciones tienen mensajes sin leer.
  Future<int> totalNoLeidos();

  /// Patrón Observer: avisos en tiempo real (Supabase Realtime, WebSocket):
  /// mensajes nuevos de MIS conversaciones y cada vez que la conexión se
  /// abre. Varios observadores pueden escuchar a la vez; la suscripción se
  /// abre con el primero y se cierra con el último.
  Stream<AvisoChat> avisos();
}
