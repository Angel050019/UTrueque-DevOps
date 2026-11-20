import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../publicaciones/domain/errors/publicacion_failures.dart';
import '../../domain/entities/resumen_reputacion.dart';
import '../../domain/entities/trato.dart';
import '../../domain/errors/reputacion_failures.dart';
import '../../domain/validators/calificacion_validator.dart';
import '../models/modelos_reputacion.dart';

/// Acceso a Supabase de la reputación (HU-09). Ver la migración
/// supabase/migrations/20261119120000_hu09_reputacion.sql.
abstract class ReputacionRemoteDataSource {
  Future<List<CompradorPosibleModel>> compradoresPosibles(String publicacionId);
  Future<String?> marcarVendida(String publicacionId, {String? conversacionId});
  Future<List<TratoPorCalificarModel>> tratosPorCalificar();
  Future<void> calificar({required String ventaId, required int estrellas, String? comentario});
  Future<ResumenReputacion> resumen(String usuarioId);
  Future<PaginaCalificaciones> recibidas({CalificacionRecibida? despuesDe, int limite = 20});
}

class ReputacionRemoteDataSourceImpl implements ReputacionRemoteDataSource {
  ReputacionRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String funcionCompradores = 'compradores_posibles';
  static const String funcionVender = 'marcar_vendida';
  static const String funcionTratos = 'tratos_por_calificar';
  static const String funcionCalificar = 'calificar';
  static const String funcionResumen = 'reputacion_usuario';
  static const String funcionRecibidas = 'calificaciones_recibidas';

  StorageFileApi get _bucket => _client.storage.from(AppConstants.bucketPublicaciones);

  void _exigirSesion() {
    if (_client.auth.currentUser == null) throw const SesionNoIniciadaFailure();
  }

  /// Llama a una función de la base y traduce sus errores.
  Future<T> _rpc<T>(String funcion, Map<String, dynamic> params) async {
    _exigirSesion();
    try {
      return await _client.rpc<T>(funcion, params: params);
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  static List<Map<String, dynamic>> _filas(Object? respuesta) =>
      respuesta is List ? respuesta.cast<Map<String, dynamic>>() : const <Map<String, dynamic>>[];

  /// `POST /rest/v1/rpc/compradores_posibles`.
  @override
  Future<List<CompradorPosibleModel>> compradoresPosibles(String publicacionId) async {
    final Object? r = await _rpc<dynamic>(funcionCompradores, <String, dynamic>{'p_publicacion': publicacionId});
    return _filas(r).map(CompradorPosibleModel.fromMap).toList(growable: false);
  }

  /// `POST /rest/v1/rpc/marcar_vendida`. Devuelve el id de la venta o `null`.
  @override
  Future<String?> marcarVendida(String publicacionId, {String? conversacionId}) async {
    final Object? r = await _rpc<dynamic>(funcionVender, <String, dynamic>{
      'p_publicacion': publicacionId,
      'p_conversacion': conversacionId,
    });
    return r is String && r.isNotEmpty ? r : null;
  }

  /// `POST /rest/v1/rpc/tratos_por_calificar`.
  @override
  Future<List<TratoPorCalificarModel>> tratosPorCalificar() async {
    final Object? r = await _rpc<dynamic>(funcionTratos, const <String, dynamic>{});
    return _filas(r)
        .map((fila) => TratoPorCalificarModel.fromMap(fila, urlFoto: _bucket.getPublicUrl))
        .toList(growable: false);
  }

  /// `POST /rest/v1/rpc/calificar`. SEGURIDAD: no se manda quién califica
  /// ni a quién; el servidor lo saca de la sesión y de la venta.
  @override
  Future<void> calificar({required String ventaId, required int estrellas, String? comentario}) async {
    await _rpc<dynamic>(funcionCalificar, <String, dynamic>{
      'p_venta': ventaId,
      'p_estrellas': estrellas,
      'p_comentario': comentario,
    });
  }

  /// `POST /rest/v1/rpc/reputacion_usuario`. Siempre regresa una fila.
  @override
  Future<ResumenReputacion> resumen(String usuarioId) async {
    final Object? r = await _rpc<dynamic>(funcionResumen, <String, dynamic>{'p_usuario': usuarioId});
    final List<Map<String, dynamic>> filas = _filas(r);
    if (filas.isEmpty) return ResumenReputacion.vacio(usuarioId);
    return ResumenReputacionModel.fromMap(filas.first, usuarioId: usuarioId);
  }

  /// `POST /rest/v1/rpc/calificaciones_recibidas`. Se pide una de más para
  /// saber si hay otra página.
  @override
  Future<PaginaCalificaciones> recibidas({CalificacionRecibida? despuesDe, int limite = 20}) async {
    final Object? r = await _rpc<dynamic>(funcionRecibidas, <String, dynamic>{
      'p_antes_de': despuesDe?.creadaEn.toUtc().toIso8601String(),
      'p_antes_id': despuesDe?.id,
      'p_limite': limite + 1,
    });
    final List<CalificacionRecibida> todas =
        _filas(r).map(CalificacionRecibidaModel.fromMap).toList(growable: false);
    return PaginaCalificaciones(
      calificaciones: todas.length > limite ? todas.sublist(0, limite) : todas,
      hayMas: todas.length > limite,
    );
  }

  /// SEGURIDAD: errores sin detalles internos. La base manda una pista fija
  /// (hint) por cada regla de HU-09.
  static Failure _traducir(PostgrestException e) {
    switch (e.hint) {
      case 'comprador_no_valido':
        return const CompradorNoValidoFailure();
      case 'calificacion_duplicada':
        return const CalificacionDuplicadaFailure();
      case 'plazo_vencido':
        return const PlazoVencidoFailure();
      case 'estrellas_invalidas':
        return const CalificacionInvalidaFailure(CalificacionValidator.mensajeEstrellas);
      case 'comentario_largo':
        return const CalificacionInvalidaFailure(CalificacionValidator.mensajeLargo);
      case 'comentario_caracteres':
        return const CalificacionInvalidaFailure(CalificacionValidator.mensajeCaracteres);
      case 'transicion_no_permitida':
        // Se vendió desde otro dispositivo (HU-06, Escenario 9).
        return const AccionNoPermitidaFailure();
      case 'publicacion_no_encontrada':
        return const PublicacionNoEncontradaFailure();
    }
    switch (e.code) {
      case '42501': // no es tu publicación o tu trato
      case '22P02': // id con formato inválido
        return const ReputacionSinPermisoFailure();
      default:
        return const ReputacionServidorFailure();
    }
  }
}
