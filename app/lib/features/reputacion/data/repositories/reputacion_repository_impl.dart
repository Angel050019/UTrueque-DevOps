import '../../domain/entities/resumen_reputacion.dart';
import '../../domain/entities/trato.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../datasources/reputacion_remote_datasource.dart';

/// Implementación de la reputación con Supabase (HU-09).
class ReputacionRepositoryImpl implements ReputacionRepository {
  ReputacionRepositoryImpl(this._remoteDataSource);

  final ReputacionRemoteDataSource _remoteDataSource;

  @override
  Future<List<CompradorPosible>> compradoresPosibles(String publicacionId) =>
      _remoteDataSource.compradoresPosibles(publicacionId);

  @override
  Future<String?> marcarVendida(String publicacionId, {String? conversacionId}) =>
      _remoteDataSource.marcarVendida(publicacionId, conversacionId: conversacionId);

  @override
  Future<List<TratoPorCalificar>> tratosPorCalificar() => _remoteDataSource.tratosPorCalificar();

  @override
  Future<void> calificar({required String ventaId, required int estrellas, String? comentario}) =>
      _remoteDataSource.calificar(ventaId: ventaId, estrellas: estrellas, comentario: comentario);

  @override
  Future<ResumenReputacion> resumen(String usuarioId) => _remoteDataSource.resumen(usuarioId);

  @override
  Future<PaginaCalificaciones> recibidas({CalificacionRecibida? despuesDe, int limite = 20}) =>
      _remoteDataSource.recibidas(despuesDe: despuesDe, limite: limite);
}
