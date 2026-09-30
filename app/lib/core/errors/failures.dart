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

// Después:
class ServidorFailure extends Failure {
  const ServidorFailure([super.mensaje = 'Ocurrió un error inesperado. Inténtalo de nuevo.']);
}
