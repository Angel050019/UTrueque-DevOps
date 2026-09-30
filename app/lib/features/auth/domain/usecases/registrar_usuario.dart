import '../../../../core/errors/failures.dart';
import '../../../../core/utils/email_validator.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: registrar un nuevo estudiante.
/// Cubre HU-01, Escenario 1 (registro exitoso) y Escenario 2 (correo no
/// institucional), validando el dominio ANTES de tocar la red.
class RegistrarUsuario {
  RegistrarUsuario(this._repository, [EmailValidator? validador])
      : _validador = validador ?? const EmailValidator();

  final AuthRepository _repository;
  final EmailValidator _validador;

  Future<Usuario> call({
    required String correo,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    final String? errorCorreo = _validador.validar(correo);
    if (errorCorreo != null) {
      throw const CorreoNoInstitucionalFailure();
    }
    if (contrasena.length < 8) {
      throw const ServidorFailure('La contraseña debe tener al menos 8 caracteres.');
    }
    if (contrasena != confirmarContrasena) {
      throw const ServidorFailure('Las contraseñas no coinciden.');
    }
    return _repository.registrar(correo: correo.trim(), contrasena: contrasena);
  }
}
