import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../domain/entities/aviso_chat.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/entities/pagina_mensajes.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/mensajes_tiempo_real.dart';
import '../models/mensaje_model.dart';

/// Implementación del chat con Supabase (HU-07).
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remoteDataSource);

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<String> iniciarConversacion(String publicacionId) => _remoteDataSource.iniciarConversacion(publicacionId);

  @override
  Future<List<Conversacion>> obtenerConversaciones() => _remoteDataSource.obtenerConversaciones();

  @override
  Future<PaginaMensajes> obtenerMensajes(String conversacionId, {CursorFeed? antesDe, required int limite}) =>
      _remoteDataSource.obtenerMensajes(conversacionId, antesDe: antesDe, limite: limite);

  @override
  Future<Mensaje> enviarMensaje(String conversacionId, String texto) =>
      _remoteDataSource.enviarMensaje(conversacionId, texto);

  @override
  Future<void> marcarLeida(String conversacionId) => _remoteDataSource.marcarLeida(conversacionId);

  @override
  Future<int> totalNoLeidos() => _remoteDataSource.totalNoLeidos();

  /// Convierte los eventos del WebSocket en avisos del dominio. Un registro
  /// que no se puede leer se ignora (no tumba la conversación).
  @override
  Stream<AvisoChat> avisos() {
    return _remoteDataSource.eventos().expand((EventoTiempoReal evento) {
      final Map<String, dynamic>? registro = evento.registro;
      if (registro == null) return const <AvisoChat>[ChatConectado()];
      try {
        return <AvisoChat>[MensajeRecibido(MensajeModel.fromMap(registro))];
      } catch (_) {
        return const <AvisoChat>[];
      }
    });
  }
}
