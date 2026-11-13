import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../chat/domain/entities/aviso_chat.dart';
import '../../../chat/domain/entities/conversacion.dart';
import '../../../chat/domain/entities/mensaje.dart';
import '../../../chat/domain/errors/chat_failures.dart';
import '../../../chat/domain/usecases/escuchar_chat.dart';
import '../../domain/entities/encuentro.dart';
import '../../domain/factories/creadores_solicitud.dart';
import '../../domain/usecases/enviar_solicitud_encuentro.dart';
import '../../domain/usecases/obtener_encuentros.dart';
import 'encuentros_state.dart';

/// Maneja los encuentros de una conversación dentro del chat (HU-08).
///
/// Observa el mismo tiempo real del chat (patrón Observer de HU-07): cuando
/// llega una tarjeta de encuentro de esta conversación, vuelve a pedir los
/// encuentros para tener su estado al día (Escenarios 1 a 4). Para aceptar,
/// rechazar o cancelar usa un creador del patrón Factory Method.
class EncuentrosCubit extends Cubit<EncuentrosState> {
  EncuentrosCubit({
    required Conversacion conversacion,
    required String? miId,
    required ObtenerEncuentros obtenerEncuentros,
    required EnviarSolicitudEncuentro enviarSolicitud,
    required EscucharChat escuchar,
    DateTime Function()? reloj,
  })  : _conversacion = conversacion,
        _miId = miId,
        _obtener = obtenerEncuentros,
        _enviar = enviarSolicitud,
        _escuchar = escuchar,
        _reloj = reloj ?? DateTime.now,
        super(const EncuentrosState());

  final Conversacion _conversacion;
  final String? _miId;
  final ObtenerEncuentros _obtener;
  final EnviarSolicitudEncuentro _enviar;
  final EscucharChat _escuchar;
  final DateTime Function() _reloj;

  StreamSubscription<AvisoChat>? _suscripcion;

  String? get miId => _miId;
  Conversacion get conversacion => _conversacion;
  DateTime get ahora => _reloj();

  /// Escenario 10: con la publicación Vendida o borrada no hay botones.
  bool get cerrada => state.cerradaPorServidor || !_conversacion.aceptaMensajes;

  /// Escenario 7: el botón "Proponer punto de encuentro" está habilitado.
  bool get puedeProponer => state.cargado && !cerrada && !state.enviando && state.activoAl(ahora) == null;

  /// Se suscribe al tiempo real y carga los encuentros.
  Future<void> cargar() async {
    _suscripcion ??= _escuchar().listen(_alAviso, onError: (Object _) {});
    await actualizar();
  }

  /// Vuelve a pedir los encuentros. Si falla, se conservan los que había
  /// (las tarjetas muestran el texto del mensaje mientras tanto).
  Future<void> actualizar() async {
    try {
      final List<Encuentro> encuentros = await _obtener(_conversacion.id);
      _emitir(state.copyWith(encuentros: List.unmodifiable(encuentros), cargado: true));
    } on ConversacionCerradaFailure {
      _emitir(state.copyWith(cargado: true, cerradaPorServidor: true));
    } catch (_) {
      // Sin conexión o error: se intentará con la siguiente tarjeta o
      // reconexión. Sin encuentros cargados no se puede proponer.
    }
  }

  /// Escenarios 2 y 3. Devuelve `true` si se envió.
  Future<bool> responder(Encuentro encuentro, {required bool acepta}) => _mandar(
        CreadorRespuesta(encuentro: encuentro, miId: _miId, acepta: acepta, reloj: _reloj),
        exito: acepta ? 'Punto de encuentro confirmado.' : 'Rechazaste la propuesta.',
      );

  /// Escenario 4. Devuelve `true` si se envió.
  Future<bool> cancelar(Encuentro encuentro) => _mandar(
        CreadorCancelacion(encuentro: encuentro, miId: _miId, reloj: _reloj),
        exito: 'Encuentro cancelado.',
      );

  /// La pantalla ya mostró el aviso.
  void avisoMostrado() {
    if (state.aviso != null) _emitir(state.copyWith(aviso: () => null));
  }

  Future<bool> _mandar(CreadorSolicitudEncuentro creador, {required String exito}) async {
    if (state.enviando || cerrada) return false;
    _emitir(state.copyWith(enviando: true, aviso: () => null));
    try {
      await _enviar(creador);
      _emitir(state.copyWith(enviando: false, aviso: () => exito, avisoEsError: false));
      await actualizar();
      return true;
    } on ConversacionCerradaFailure catch (falla) {
      _emitir(state.copyWith(enviando: false, cerradaPorServidor: true, aviso: () => falla.mensaje, avisoEsError: true));
    } catch (error) {
      final Failure falla = error is Failure ? error : const ChatServidorFailure();
      _emitir(state.copyWith(enviando: false, aviso: () => falla.mensaje, avisoEsError: true));
      // Si el servidor dice que ya no está pendiente, se trae el estado real.
      unawaited(actualizar());
    }
    return false;
  }

  void _alAviso(AvisoChat aviso) {
    switch (aviso) {
      case MensajeRecibido(:final Mensaje mensaje):
        if (mensaje.conversacionId == _conversacion.id && mensaje.esDeEncuentro) unawaited(actualizar());
      case ChatConectado():
        unawaited(actualizar());
    }
  }

  void _emitir(EncuentrosState nuevo) {
    if (!isClosed) emit(nuevo);
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
