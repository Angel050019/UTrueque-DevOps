import '../../domain/entities/categoria.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/entities/modalidad.dart';
import '../../domain/entities/publicacion.dart';
import '../../domain/repositories/publicacion_repository.dart';
import '../datasources/publicacion_remote_datasource.dart';

/// Implementación concreta de [PublicacionRepository] que delega en Supabase.
class PublicacionRepositoryImpl implements PublicacionRepository {
  PublicacionRepositoryImpl(this._remoteDataSource);

  final PublicacionRemoteDataSource _remoteDataSource;

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
}
