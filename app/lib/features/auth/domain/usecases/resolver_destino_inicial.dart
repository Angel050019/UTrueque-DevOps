import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// A dónde debe ir el usuario al abrir la app o después de iniciar sesión.
enum DestinoInicial {
  login,
  completarPerfil,
  feed;

  /// Regla de HU-02: sin sesión → login; con sesión y perfil incompleto →
  /// completar perfil; con perfil completo → feed.
  static DestinoInicial desde(Usuario? usuario) {
    if (usuario == null) return DestinoInicial.login;
    return usuario.perfilCompleto ? DestinoInicial.feed : DestinoInicial.completarPerfil;
  }
}

/// Caso de uso: decidir la pantalla inicial al abrir la app (Splash).
class ResolverDestinoInicial {
  ResolverDestinoInicial(this._repository);

  final AuthRepository _repository;

  Future<DestinoInicial> call() async {
    try {
      final Usuario? usuario = await _repository.obtenerSesionActual();
      return DestinoInicial.desde(usuario);
    } catch (_) {
      // Sin red o error del servidor: si hay sesión guardada se respeta el
      // comportamiento de HU-01 (ir al Feed); si no, al login.
      return _repository.usuarioActual == null ? DestinoInicial.login : DestinoInicial.feed;
    }
  }
}
