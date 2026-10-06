import '../../domain/entities/division.dart';
import '../../domain/entities/foto_perfil.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../datasources/perfil_remote_datasource.dart';

/// Implementación concreta de [PerfilRepository] que delega en Supabase.
class PerfilRepositoryImpl implements PerfilRepository {
  PerfilRepositoryImpl(this._remoteDataSource);

  final PerfilRemoteDataSource _remoteDataSource;

  @override
  Future<Perfil> obtenerPerfilPropio() => _remoteDataSource.obtenerPerfilPropio();

  @override
  Future<Perfil> obtenerPerfilPorId(String id) => _remoteDataSource.obtenerPerfilPorId(id);

  @override
  Future<Perfil> actualizarPerfil({
    required String nombreMostrar,
    required int divisionId,
    required int carreraId,
    String? fotoUrl,
  }) {
    return _remoteDataSource.actualizarPerfil(
      nombreMostrar: nombreMostrar,
      divisionId: divisionId,
      carreraId: carreraId,
      fotoUrl: fotoUrl,
    );
  }

  @override
  Future<String> subirFoto(FotoPerfil foto) => _remoteDataSource.subirFoto(foto);

  @override
  Future<List<Division>> obtenerCatalogoAcademico() =>
      _remoteDataSource.obtenerCatalogoAcademico();
}
