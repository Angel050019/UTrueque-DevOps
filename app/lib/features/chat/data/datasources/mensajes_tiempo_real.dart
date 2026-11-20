import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mensaje_model.dart';

/// Lo que llega por el WebSocket: un registro nuevo de la tabla mensajes o
/// el aviso de que la conexión se abrió.
class EventoTiempoReal {
  const EventoTiempoReal.registro(Map<String, dynamic> this.registro);
  const EventoTiempoReal.conectado() : registro = null;

  final Map<String, dynamic>? registro;
}

/// HU-07, patrón Observer: el SUJETO que avisa de los mensajes nuevos.
///
/// Está detrás de esta interfaz para que las pruebas puedan simularlo con un
/// `StreamController` (el WebSocket real no se puede abrir en el CI).
abstract class MensajesEnTiempoReal {
  Stream<EventoTiempoReal> eventos();
}

/// Implementación con Supabase Realtime (WebSocket cifrado, WSS/TLS).
///
/// SEGURIDAD: Realtime respeta las reglas RLS de la tabla mensajes, así que
/// cada estudiante solo recibe los mensajes de sus conversaciones. Por eso
/// no hace falta filtrar por estudiante aquí.
///
/// Abre UN canal cuando aparece el primer observador y lo cierra cuando se
/// va el último (`StreamController.broadcast` con onListen y onCancel).
class MensajesRealtimeSupabase implements MensajesEnTiempoReal {
  MensajesRealtimeSupabase(this._client);

  final SupabaseClient _client;
  StreamController<EventoTiempoReal>? _controlador;
  RealtimeChannel? _canal;

  @override
  Stream<EventoTiempoReal> eventos() {
    _controlador ??= StreamController<EventoTiempoReal>.broadcast(onListen: _abrir, onCancel: _cerrar);
    return _controlador!.stream;
  }

  void _abrir() {
    _canal = _client
        .channel('mensajes-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: MensajeModel.tablaMensajes,
          callback: (payload) => _controlador?.add(EventoTiempoReal.registro(payload.newRecord)),
        )
        .subscribe((estado, _) {
      if (estado == RealtimeSubscribeStatus.subscribed) {
        _controlador?.add(const EventoTiempoReal.conectado());
      }
    });
  }

  Future<void> _cerrar() async {
    final RealtimeChannel? canal = _canal;
    _canal = null;
    if (canal != null) await _client.removeChannel(canal);
  }
}
