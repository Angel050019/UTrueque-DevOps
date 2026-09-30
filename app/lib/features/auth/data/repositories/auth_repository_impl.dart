import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta del contrato de dominio, delegando en el
/// datasource remoto. Punto único donde, a futuro, se podría agregar
/// caché local u otras fuentes de datos.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Usuario> registrar({required String correo, required String contrasena}) {
    return _remoteDataSource.registrar(correo: correo, contrasena: contrasena);
  }

  @override
  Future<Usuario> iniciarSesion({required String correo, required String contrasena}) {
    return _remoteDataSource.iniciarSesion(correo: correo, contrasena: contrasena);
  }

  @override
  Future<void> cerrarSesion() => _remoteDataSource.cerrarSesion();

  @override
  Usuario? get usuarioActual => _remoteDataSource.usuarioActual;
}
