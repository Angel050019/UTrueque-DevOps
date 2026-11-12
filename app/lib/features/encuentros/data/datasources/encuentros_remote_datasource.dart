import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../chat/domain/errors/chat_failures.dart';
import '../../domain/entities/solicitud_encuentro.dart';
import '../../domain/errors/encuentro_failures.dart';
import '../models/encuentro_model.dart';

/// Acceso a Supabase de los puntos de encuentro (HU-08). Ver la migración
/// supabase/migrations/20261111120000_hu08_punto_encuentro.sql.
abstract class EncuentrosRemoteDataSource {
  Future<List<PuntoEncuentroModel>> obtenerPuntos();
  Future<List<EncuentroModel>> obtenerEncuentros(String conversacionId);
  Future<void> enviar(SolicitudEncuentro solicitud);
}

class EncuentrosRemoteDataSourceImpl implements EncuentrosRemoteDataSource {
  EncuentrosRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String funcionProponer = 'proponer_encuentro';
  static const String funcionResponder = 'responder_encuentro';
  static const String funcionCancelar = 'cancelar_encuentro';
  static const String funcionEncuentros = 'encuentros_conversacion';

  void _exigirSesion() {
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
  }

  /// `GET /rest/v1/puntos_encuentro?select=id,nombre,referencia&activo=eq.true&order=orden`.
  @override
  Future<List<PuntoEncuentroModel>> obtenerPuntos() async {
    _exigirSesion();
    try {
      final List<Map<String, dynamic>> filas = await _client
          .from(PuntoEncuentroModel.tabla)
          .select(PuntoEncuentroModel.columnasSelect)
          .eq('activo', true)
          // Ojo: en supabase-dart `order` es descendente por defecto.
          .order('orden', ascending: true);
      return filas.map(PuntoEncuentroModel.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// `POST /rest/v1/rpc/encuentros_conversacion`.
  @override
  Future<List<EncuentroModel>> obtenerEncuentros(String conversacionId) async {
    _exigirSesion();
    try {
      final List<dynamic> filas = await _client.rpc<List<dynamic>>(
        funcionEncuentros,
        params: <String, dynamic>{'p_conversacion': conversacionId},
      );
      return filas.cast<Map<String, dynamic>>().map(EncuentroModel.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// Cada clase de solicitud va a su función. SEGURIDAD: no se manda quién
  /// propone o responde; el servidor lo toma de la sesión.
  @override
  Future<void> enviar(SolicitudEncuentro solicitud) async {
    _exigirSesion();
    final (String funcion, Map<String, dynamic> params) = switch (solicitud) {
      PropuestaEncuentro(:final conversacionId, :final puntoId, :final fechaHora) => (
          funcionProponer,
          <String, dynamic>{
            'p_conversacion': conversacionId,
            'p_punto': puntoId,
            'p_fecha_hora': fechaHora.toUtc().toIso8601String(),
          },
        ),
      RespuestaEncuentro(:final encuentroId, :final acepta) => (
          funcionResponder,
          <String, dynamic>{'p_encuentro': encuentroId, 'p_acepta': acepta},
        ),
      CancelacionEncuentro(:final encuentroId) => (
          funcionCancelar,
          <String, dynamic>{'p_encuentro': encuentroId},
        ),
    };
    try {
      await _client.rpc<dynamic>(funcion, params: params);
    } on PostgrestException catch (e) {
      throw _traducir(e, cancelando: solicitud is CancelacionEncuentro);
    }
  }

  /// SEGURIDAD: errores sin detalles internos. La base manda una pista fija
  /// (hint) por cada regla de HU-08.
  Failure _traducir(PostgrestException e, {bool cancelando = false}) {
    switch (e.hint) {
      case 'punto_no_permitido':
        return const PuntoNoPermitidoFailure();
      case 'horario_no_permitido':
        return const HorarioNoPermitidoFailure();
      case 'encuentro_activo':
        return const EncuentroActivoFailure();
      case 'encuentro_propio':
        return cancelando ? const CancelarNoPermitidoFailure() : const EncuentroPropioFailure();
      case 'encuentro_no_pendiente':
        return const EncuentroNoPendienteFailure();
      case 'encuentro_no_activo':
        return const EncuentroNoActivoFailure();
      case 'encuentro_vencido':
        return const EncuentroVencidoFailure();
      case 'conversacion_cerrada':
        return const ConversacionCerradaFailure();
      case 'demasiados_mensajes':
        return const DemasiadosMensajesFailure();
    }
    switch (e.code) {
      case '42501': // RLS o la conversación no es del estudiante
      case '22P02': // id con formato inválido
        return const ChatSinPermisoFailure();
      default:
        return const ChatServidorFailure();
    }
  }
}
