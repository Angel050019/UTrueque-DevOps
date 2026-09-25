import '../entities/usuario.dart';

/// Contrato que la capa de datos debe implementar. La capa de dominio y de
/// presentación solo conocen esta interfaz, nunca a Supabase directamente.
abstract class AuthRepository {
  /// Crea una cuenta nueva. Lanza un [Failure] si el correo no es
  /// institucional o si Supabase rechaza la operación.
  Future<Usuario> registrar({
    required String correo,
    required String contrasena,
  });

  /// Inicia sesión con credenciales existentes. Lanza un [Failure] si las
  /// credenciales son inválidas o si el servidor falla.
  Future<Usuario> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Cierra la sesión activa.
  Future<void> cerrarSesion();

  /// Usuario actualmente autenticado, o `null` si no hay sesión activa.
  Usuario? get usuarioActual;
}
