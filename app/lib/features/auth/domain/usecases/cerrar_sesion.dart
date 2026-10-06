import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar la sesión activa (se usa desde "Mi perfil").
class CerrarSesion {
  CerrarSesion(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.cerrarSesion();
}
