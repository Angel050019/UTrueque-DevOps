import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/entities/pagina_feed.dart';
import '../../../publicaciones/domain/errors/publicacion_failures.dart';
import '../../domain/entities/pagina_mensajes.dart';
import '../../domain/errors/chat_failures.dart';
import '../../domain/validators/mensaje_validator.dart';
import '../models/conversacion_model.dart';
import '../models/mensaje_model.dart';
import 'mensajes_tiempo_real.dart';

/// Acceso a Supabase del chat (HU-07). Ver la migración
/// supabase/migrations/20261106120000_hu07_chat.sql.
abstract class ChatRemoteDataSource {
  Future<String> iniciarConversacion(String publicacionId);
  Future<List<ConversacionModel>> obtenerConversaciones();
  Future<PaginaMensajes> obtenerMensajes(String conversacionId, {CursorFeed? antesDe, required int limite});
  Future<MensajeModel> enviarMensaje(String conversacionId, String texto);
  Future<void> marcarLeida(String conversacionId);
  Future<int> totalNoLeidos();
  Stream<EventoTiempoReal> eventos();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client, {MensajesEnTiempoReal? tiempoReal})
      : _tiempoReal = tiempoReal ?? MensajesRealtimeSupabase(_client);

  final SupabaseClient _client;
  final MensajesEnTiempoReal _tiempoReal;

  static const String funcionIniciar = 'iniciar_conversacion';
  static const String funcionConversaciones = 'mis_conversaciones';
  static const String funcionMensajes = 'mensajes_conversacion';
  static const String funcionMarcarLeida = 'marcar_conversacion_leida';
  static const String funcionNoLeidos = 'total_no_leidos';

  /// Conversaciones que se piden para la bandeja (la base entrega máx. 100).
  static const int conversacionesPorPeticion = 50;

  StorageFileApi get _bucket => _client.storage.from(AppConstants.bucketPublicaciones);

  void _exigirSesion() {
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
  }

  /// `POST /rest/v1/rpc/iniciar_conversacion`. SEGURIDAD: no se manda quién
  /// escribe; el servidor lo toma de la sesión.
  @override
  Future<String> iniciarConversacion(String publicacionId) async {
    _exigirSesion();
    try {
      return await _client.rpc<String>(funcionIniciar, params: <String, dynamic>{'p_publicacion': publicacionId});
    } on PostgrestException catch (e) {
      throw _traducir(e, idInvalido: const PublicacionNoEncontradaFailure());
    }
  }

  /// `POST /rest/v1/rpc/mis_conversaciones`.
  @override
  Future<List<ConversacionModel>> obtenerConversaciones() async {
    _exigirSesion();
    try {
      final List<dynamic> filas = await _client.rpc<List<dynamic>>(
        funcionConversaciones,
        params: <String, dynamic>{'p_limite': conversacionesPorPeticion},
      );
      return filas
          .cast<Map<String, dynamic>>()
          .map((fila) => ConversacionModel.fromMap(fila, urlFoto: _bucket.getPublicUrl))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// `POST /rest/v1/rpc/mensajes_conversacion`, con cursor como el Feed.
  @override
  Future<PaginaMensajes> obtenerMensajes(String conversacionId, {CursorFeed? antesDe, required int limite}) async {
    _exigirSesion();
    try {
      final List<dynamic> respuesta = await _client.rpc<List<dynamic>>(
        funcionMensajes,
        params: <String, dynamic>{
          'p_conversacion': conversacionId,
          'p_limite': limite,
          if (antesDe != null) 'p_antes_de': antesDe.fecha,
          if (antesDe != null) 'p_antes_id': antesDe.id,
        },
      );
      final List<Map<String, dynamic>> filas = respuesta.cast<Map<String, dynamic>>().toList(growable: false);
      return PaginaMensajes(
        mensajes: filas.map(MensajeModel.fromMap).toList(growable: false),
        siguiente: filas.length < limite
            ? null
            : CursorFeed(fecha: filas.last['created_at'] as String, id: filas.last['id'] as String),
      );
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// `POST /rest/v1/mensajes` y devuelve el mensaje guardado.
  @override
  Future<MensajeModel> enviarMensaje(String conversacionId, String texto) async {
    _exigirSesion();
    try {
      final Map<String, dynamic> fila = await _client
          .from(MensajeModel.tablaMensajes)
          .insert(MensajeModel.paraEnviar(conversacionId, texto))
          .select(MensajeModel.columnasSelect)
          .single();
      return MensajeModel.fromMap(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// `POST /rest/v1/rpc/marcar_conversacion_leida`.
  @override
  Future<void> marcarLeida(String conversacionId) async {
    _exigirSesion();
    try {
      await _client.rpc<dynamic>(funcionMarcarLeida, params: <String, dynamic>{'p_conversacion': conversacionId});
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// `POST /rest/v1/rpc/total_no_leidos`.
  @override
  Future<int> totalNoLeidos() async {
    _exigirSesion();
    try {
      final num total = await _client.rpc<num>(funcionNoLeidos, params: const <String, dynamic>{});
      return total.toInt();
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Stream<EventoTiempoReal> eventos() => _tiempoReal.eventos();

  /// SEGURIDAD: errores sin detalles internos. La base manda una pista fija
  /// (hint) por cada regla de HU-07.
  Failure _traducir(PostgrestException e, {Failure idInvalido = const ChatSinPermisoFailure()}) {
    switch (e.hint) {
      case 'publicacion_propia':
        return const PublicacionPropiaFailure();
      case 'publicacion_no_disponible':
        return const PublicacionNoDisponibleFailure();
      case 'perfil_incompleto':
        return const PerfilIncompletoChatFailure();
      case 'publicacion_no_encontrada':
        return const PublicacionNoEncontradaFailure();
      case 'conversacion_cerrada':
        return const ConversacionCerradaFailure();
      case 'mensaje_caracteres':
        return const MensajeInvalidoFailure(MensajeValidator.mensajeCaracteres);
      case 'demasiados_mensajes':
        return const DemasiadosMensajesFailure();
    }
    switch (e.code) {
      case '42501': // RLS: la conversación no es del estudiante
        return const ChatSinPermisoFailure();
      case '23514': // check: longitud del mensaje
        return const MensajeInvalidoFailure(MensajeValidator.mensajeLongitud);
      case '22P02': // id con formato inválido
        return idInvalido;
      default:
        return const ChatServidorFailure();
    }
  }
}
