import '../constants/app_constants.dart';

/// Valida que un correo tenga formato válido y pertenezca al dominio
/// institucional de la UTSJR. Es el núcleo de la Historia de Usuario HU-01.
class EmailValidator {
  const EmailValidator();

  static final RegExp _formatoCorreo = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  /// Devuelve `true` si [correo] tiene un formato de correo válido.
  bool tieneFormatoValido(String correo) => _formatoCorreo.hasMatch(correo.trim());

  /// Devuelve `true` si [correo] termina exactamente en el dominio
  /// institucional (`@alumno.utsjr.edu.mx`), sin importar mayúsculas.
  bool esInstitucional(String correo) {
    final String normalizado = correo.trim().toLowerCase();
    return normalizado.endsWith(AppConstants.dominioInstitucional.toLowerCase());
  }

  /// Valida formato y dominio institucional en un solo paso.
  /// Devuelve `null` si es válido, o el mensaje de error correspondiente.
  String? validar(String correo) {
    if (correo.trim().isEmpty) {
      return 'Ingresa tu correo institucional.';
    }
    if (!tieneFormatoValido(correo)) {
      return 'Ingresa un correo con formato válido.';
    }
    if (!esInstitucional(correo)) {
      return 'Debes usar tu correo institucional para registrarte.';
    }
    return null;
  }
}
