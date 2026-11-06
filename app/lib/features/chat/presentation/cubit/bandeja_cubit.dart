import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/aviso_chat.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/errors/chat_failures.dart';
import '../../domain/usecases/escuchar_chat.dart';
import '../../domain/usecases/obtener_conversaciones.dart';
import 'bandeja_state.dart';

/// Maneja la bandeja de mensajes (HU-07, Escenarios 3, 7 y 8).
///
/// Patrón Observer: cuando llega un mensaje, la conversación sube al primer
/// lugar con su último texto y sus no leídos, sin recargar la pantalla. Si
/// es de una conversación nueva, recarga la bandeja.
class BandejaCubit extends Cubit<BandejaState> {
  BandejaCubit({
    required ObtenerConversaciones obtenerConversaciones,
    required EscucharChat escuchar,
    required String? miId,
  })  : _obtener = obtenerConversaciones,
        _escuchar = escuchar,
        _miId = miId,
        super(const BandejaCargando());

  final ObtenerConversaciones _obtener;
  final EscucharChat _escuchar;
  final String? _miId;

  StreamSubscription<AvisoChat>? _suscripcion;

  /// Número de la carga actual: una respuesta vieja se ignora.
  int _carga = 0;

  /// La primera conexión del tiempo real no necesita recargar.
  bool _yaConectado = false;

  String? get miId => _miId;

  /// Primera carga (también es "Reintentar").
  Future<void> cargar() async {
    _suscripcion ??= _escuchar().listen(_alAviso, onError: (Object _) {});
    _emitir(const BandejaCargando());
    await _cargar(++_carga);
  }

  /// "Jalar para actualizar" o al regresar de un chat: recarga sin quitar la
  /// lista que ya se ve.
  Future<void> actualizar() => _cargar(++_carga);

  Future<void> _cargar(int carga) async {
    try {
      final List<Conversacion> lista = await _obtener();
      if (carga != _carga) return;
      _emitir(lista.isEmpty ? const BandejaVacia() : BandejaCargada(List.unmodifiable(lista)));
    } catch (error) {
      if (carga != _carga) return;
      final Failure falla = error is Failure ? error : const ChatServidorFailure();
      final BandejaState actual = state;
      _emitir(actual is BandejaCargada ? BandejaCargada(actual.conversaciones, aviso: falla.mensaje) : BandejaError(falla));
    }
  }

  /// Escenario 8: al abrir una conversación, su globo se apaga de inmediato.
  void marcarLeida(String conversacionId) {
    final BandejaState actual = state;
    if (actual is! BandejaCargada) return;
    _emitir(BandejaCargada(
      List.unmodifiable(actual.conversaciones.map((c) => c.id == conversacionId ? c.leida() : c)),
    ));
  }

  void avisoMostrado() {
    final BandejaState actual = state;
    if (actual is BandejaCargada && actual.aviso != null) _emitir(BandejaCargada(actual.conversaciones));
  }

  void _alAviso(AvisoChat aviso) {
    switch (aviso) {
      case MensajeRecibido(:final Mensaje mensaje):
        final BandejaState actual = state;
        final int i =
            actual is BandejaCargada ? actual.conversaciones.indexWhere((c) => c.id == mensaje.conversacionId) : -1;
        if (actual is BandejaCargada && i >= 0) {
          final Conversacion cambiada = actual.conversaciones[i].conMensaje(mensaje, miId: _miId);
          _emitir(BandejaCargada(List.unmodifiable(<Conversacion>[
            cambiada,
            ...actual.conversaciones.where((c) => c.id != mensaje.conversacionId),
          ])));
        } else {
          // Una conversación nueva (por ejemplo, alguien me escribió por
          // primera vez): se recarga para traer sus datos.
          unawaited(actualizar());
        }
      case ChatConectado():
        if (_yaConectado) unawaited(actualizar());
        _yaConectado = true;
    }
  }

  void _emitir(BandejaState nuevo) {
    if (!isClosed) emit(nuevo);
  }

  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    return super.close();
  }
}
