import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión con correo y contraseña.
/// Cubre HU-01, Escenario 3 (sin conexión), 4 (éxito) y 5 (credenciales
/// incorrectas). La verificación de conectividad se hace ANTES de llamar
/// al repositorio, para no depender del timeout de red de Supabase.
class IniciarSesion {
  IniciarSesion(this._repository, this._networkInfo);

  final AuthRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Usuario> call({
    required String correo,
    required String contrasena,
  }) async {
    final bool conectado = await _networkInfo.estaConectado;
    if (!conectado) {
      throw const SinConexionFailure();
    }
    if (correo.trim().isEmpty || contrasena.isEmpty) {
      throw const CredencialesInvalidasFailure();
    }
    return _repository.iniciarSesion(correo: correo.trim(), contrasena: contrasena);
  }
}
