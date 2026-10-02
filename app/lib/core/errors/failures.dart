import 'package:equatable/equatable.dart';

/// Representa un fallo de negocio o de infraestructura que la capa de
/// dominio/presentación necesita entender, sin acoplarse a excepciones
/// específicas de Supabase o de red.
abstract class Failure extends Equatable {
  const Failure(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

/// El correo ingresado no pertenece al dominio institucional.
/// Ver HU-01, Escenario 2: Registro rechazado por correo no institucional.
class CorreoNoInstitucionalFailure extends Failure {
  const CorreoNoInstitucionalFailure()
      : super('Debes usar tu correo institucional para registrarte.');
}

/// No hay conexión a internet disponible.
/// Ver HU-01, Escenario 3: Inicio de sesión sin conexión a internet.
class SinConexionFailure extends Failure {
  const SinConexionFailure()
      : super('Sin conexión a internet. Verifica tu red e inténtalo de nuevo.');
}

/// Las credenciales ingresadas son incorrectas.
/// Ver HU-01, Escenario 5: Credenciales incorrectas.
class CredencialesInvalidasFailure extends Failure {
  const CredencialesInvalidasFailure()
      : super('Correo o contraseña incorrectos.');
}

/// Error genérico de servidor o inesperado.
class ServidorFailure extends Failure {
  const ServidorFailure([super.mensaje = 'Ocurrió un error inesperado. Inténtalo de nuevo.']);
}

// ---------------------------------------------------------------------------
// HU-02: Perfil Académico
// ---------------------------------------------------------------------------

/// No hay una sesión activa (expiró o el usuario cerró sesión).
class SesionNoIniciadaFailure extends Failure {
  const SesionNoIniciadaFailure()
      : super('Tu sesión expiró. Inicia sesión de nuevo.');
}

/// No existe el perfil solicitado.
class PerfilNoEncontradoFailure extends Failure {
  const PerfilNoEncontradoFailure() : super('No se encontró el perfil.');
}

/// El nombre a mostrar no cumple la regla de 3 a 50 caracteres.
class NombreInvalidoFailure extends Failure {
  const NombreInvalidoFailure(super.mensaje);
}

/// No se eligió división.
class DivisionRequeridaFailure extends Failure {
  const DivisionRequeridaFailure() : super('Selecciona tu división.');
}

/// No se eligió carrera.
class CarreraRequeridaFailure extends Failure {
  const CarreraRequeridaFailure() : super('Selecciona tu carrera.');
}

/// La carrera elegida no pertenece a la división elegida.
/// Ver HU-02, Escenario 2.
class CarreraNoPerteneceFailure extends Failure {
  const CarreraNoPerteneceFailure()
      : super('La carrera seleccionada no pertenece a la división elegida.');
}

/// La foto no es JPG ni PNG.
class FotoFormatoInvalidoFailure extends Failure {
  const FotoFormatoInvalidoFailure()
      : super('La foto debe ser una imagen JPG o PNG.');
}

/// La foto pesa más de 5 MB. Ver HU-02, Escenario 3.
class FotoDemasiadoGrandeFailure extends Failure {
  const FotoDemasiadoGrandeFailure()
      : super('La foto no puede pesar más de 5 MB.');
}
