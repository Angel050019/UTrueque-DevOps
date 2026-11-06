import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/aviso_chat.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/entities/pagina_mensajes.dart';
import '../../domain/errors/chat_failures.dart';
import '../../domain/usecases/enviar_mensaje.dart';
import '../../domain/usecases/escuchar_chat.dart';
import '../../domain/usecases/marcar_conversacion_leida.dart';
import '../../domain/usecases/obtener_mensajes.dart';
import 'chat_state.dart';

/// Maneja la pantalla "Chat" (HU-07).
///
/// Patrón Observer: al abrir se suscribe al tiempo real ([EscucharChat]).
/// Cuando llega un mensaje de esta conversación, lo agrega sin recargar la
/// pantalla (Escenario 3). Al cerrarse, cancela su suscripción.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required Conversacion conversacion,
    required String? miId,
    required ObtenerMensajes obtenerMensajes,
    required EnviarMensaje enviarMensaje,
    required MarcarConversacionLeida marcarLeida,
    required EscucharChat escuchar,
  })  : _miId = miId,
        _obtener = obtenerMensajes,
        _enviar = enviarMensaje,
        _marcarLeida = marcarLeida,
        _escuchar = escuchar,
        super(ChatCargando(conversacion));

  final String? _miId;
  final ObtenerMensajes _obtener;
  final EnviarMensaje _enviar;
  final MarcarConversacionLeida _marcarLeida;
  final EscucharChat _escuchar;

  StreamSubscription<AvisoChat>? _suscripcion;

  /// Mensajes que llegaron mientras se cargaba la primera página.
  final List<Mensaje> _pendientes = <Mensaje>[];

  String? get miId => _miId;

  /// Abre el chat (también es "Reintentar"): primero se suscribe al tiempo
  /// real y después carga los últimos 30 mensajes, para no perder ninguno.
  Future<void> abrir() async {
    _suscripcion ??= _escuchar().listen(_alAviso, onError: (Object _) {});
    _emitir(ChatCargando(state.conversacion));
    try {
      final PaginaMensajes pagina = await _obtener(state.conversacion.id);
      final List<Mensaje> mensajes = _unir(pagina.mensajes.reversed, _pendientes);
      _pendientes.clear();
      _emitir(ChatListo(state.conversacion, mensajes: mensajes, siguiente: pagina.siguiente));
      // Escenario 8: al abrir, los mensajes quedan como leídos.
      unawaited(_marcarLeida(state.conversacion.id));
    } catch (error) {
      _emitir(ChatError(state.conversacion, _comoFailure(error)));
    }
  }

  /// Escenario 9: los 30 mensajes anteriores al subir hasta el principio.
  Future<void> cargarAnteriores() async {
    final ChatState inicial = state;
    if (inicial is! ChatListo || inicial.cargandoAnteriores || !inicial.hayAnteriores) return;
    _emitir(inicial.copyWith(cargandoAnteriores: true, errorAnteriores: () => null));
    try {
      final PaginaMensajes pagina = await _obtener(inicial.conversacion.id, antesDe: inicial.siguiente);
      final ChatState actual = state;
      if (actual is! ChatListo) return;
      _emitir(actual.copyWith(
        mensajes: _unir(pagina.mensajes.reversed, actual.mensajes),
        siguiente: () => pagina.siguiente,
        cargandoAnteriores: false,
      ));
    } catch (error) {
      final ChatState actual = state;
      if (actual is! ChatListo) return;
      _emitir(actual.copyWith(cargandoAnteriores: false, errorAnteriores: () => _comoFailure(error).mensaje));
    }
  }

  /// Escenarios 3, 10, 11, 13 y 14. Devuelve `true` si se envió, para que la
  /// pantalla borre el campo; si no, el texto se conserva.
  Future<bool> enviar(String texto) async {
    final ChatState inicial = state;
    if (inicial is! ChatListo || inicial.enviando || inicial.cerrada) return false;
    _emitir(inicial.copyWith(enviando: true, aviso: () => null));
    try {
      final Mensaje mensaje = await _enviar(inicial.conversacion, texto);
      final ChatState actual = state;
      if (actual is ChatListo) {
        _emitir(actual.copyWith(mensajes: _unir(actual.mensajes, <Mensaje>[mensaje]), enviando: false));
      }
      return true;
    } on ConversacionCerradaFailure catch (falla) {
      _conAviso(falla.mensaje, cerrada: true);
    } catch (error) {
      _conAviso(_comoFailure(error).mensaje);
    }
    return false;
  }

  /// La pantalla ya mostró el aviso.
  void avisoMostrado() {
    final ChatState actual = state;
    if (actual is ChatListo && actual.aviso != null) _emitir(actual.copyWith(aviso: () => null));
  }

  void _alAviso(AvisoChat aviso) {
    switch (aviso) {
      case MensajeRecibido(:final Mensaje mensaje):
        if (mensaje.conversacionId != state.conversacion.id) return;
        final ChatState actual = state;
        if (actual is ChatListo) {
          _emitir(actual.copyWith(mensajes: _unir(actual.mensajes, <Mensaje>[mensaje])));
          if (!mensaje.esDe(_miId)) unawaited(_marcarLeida(actual.conversacion.id));
        } else {
          _pendientes.add(mensaje);
        }
      case ChatConectado():
        // La conexión se abrió o se recuperó: se piden los últimos mensajes
        // por si llegó alguno mientras no había conexión.
        final ChatState actual = state;
        if (actual is ChatError) {
          unawaited(abrir());
        } else if (actual is ChatListo) {
          unawaited(_sincronizar());
        }
    }
  }

  Future<void> _sincronizar() async {
    try {
      final PaginaMensajes pagina = await _obtener(state.conversacion.id);
      final ChatState actual = state;
      if (actual is! ChatListo) return;
      final List<Mensaje> unidos = _unir(actual.mensajes, pagina.mensajes);
      if (unidos.length != actual.mensajes.length) {
        _emitir(actual.copyWith(mensajes: unidos));
        unawaited(_marcarLeida(actual.conversacion.id));
      }
    } catch (_) {
      // Sin conexión: se intentará en la siguiente reconexión.
    }
  }

  void _conAviso(String mensaje, {bool cerrada = false}) {
    final ChatState actual = state;
    if (actual is! ChatListo) return;
    _emitir(actual.copyWith(
      enviando: false,
      aviso: () => mensaje,
      cerradaPorServidor: cerrada ? true : null,
    ));
  }

  /// Une dos listas sin repetir mensajes (el propio llega dos veces: como
  /// respuesta del envío y por el tiempo real) y las ordena por fecha.
  static List<Mensaje> _unir(Iterable<Mensaje> a, Iterable<Mensaje> b) {
    final Map<String, Mensaje> porId = <String, Mensaje>{
      for (final Mensaje m in a) m.id: m,
      for (final Mensaje m in b) m.id: m,
    };
    final List<Mensaje> lista = porId.values.toList()
      ..sort((x, y) {
        final int porFecha = x.creadoEn.compareTo(y.creadoEn);
        return porFecha != 0 ? porFecha : x.id.compareTo(y.id);
      });
    return List.unmodifiable(lista);
  }

  static Failure _comoFailure(Object error) => error is Failure ? error : const ChatServidorFailure();

  void _emitir(ChatState nuevo) {
    if (!isClosed) emit(nuevo);
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
