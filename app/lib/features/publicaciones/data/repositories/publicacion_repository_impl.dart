import '../../domain/entities/categoria.dart';
import '../../domain/entities/estado_publicacion.dart';
import '../../domain/entities/filtros_feed.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/pagina_feed.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/repositories/publicacion_repository.dart';
import '../datasources/publicacion_remote_datasource.dart';

/// Implementación concreta de [PublicacionRepository] que delega en Supabase.
class PublicacionRepositoryImpl implements PublicacionRepository {
  PublicacionRepositoryImpl(this._remoteDataSource);

  final PublicacionRemoteDataSource _remoteDataSource;

  @override
  Future<PaginaFeed> buscarPublicaciones({
    FiltrosFeed filtros = const FiltrosFeed(),
    CursorFeed? despuesDe,
    required int limite,
  }) =>
      _remoteDataSource.buscarPublicaciones(filtros: filtros, despuesDe: despuesDe, limite: limite);

  @override
  Future<Publicacion> obtenerDetalle(String id) => _remoteDataSource.obtenerDetalle(id);

  @override
  Future<List<Categoria>> obtenerCategorias() => _remoteDataSource.obtenerCategorias();

  @override
  Future<String> subirFoto(FotoArticulo foto) => _remoteDataSource.subirFoto(foto);

  @override
  Future<void> eliminarFotos(List<String> rutas) => _remoteDataSource.eliminarFotos(rutas);

  @override
  Future<Publicacion> crearPublicacion({
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  }) {
    return _remoteDataSource.crearPublicacion(
      titulo: titulo,
      descripcion: descripcion,
      categoriaId: categoriaId,
      modalidad: modalidad,
      precio: precio,
      fotos: fotos,
    );
  }

  @override
  Future<PaginaFeed> obtenerMisPublicaciones({
    required bool finalizadas,
    CursorFeed? despuesDe,
    required int limite,
  }) =>
      _remoteDataSource.obtenerMisPublicaciones(
        finalizadas: finalizadas,
        despuesDe: despuesDe,
        limite: limite,
      );

  @override
  Future<Publicacion> cambiarEstado(String id, EstadoPublicacion nuevo) =>
      _remoteDataSource.cambiarEstado(id, nuevo);

  @override
  Future<Publicacion> editarPublicacion({
    required String id,
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required Modalidad modalidad,
    required double? precio,
    required List<String> fotos,
  }) {
    return _remoteDataSource.editarPublicacion(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      categoriaId: categoriaId,
      modalidad: modalidad,
      precio: precio,
      fotos: fotos,
    );
  }

  @override
  Future<List<String>> borrarPublicacion(String id) => _remoteDataSource.borrarPublicacion(id);
}
