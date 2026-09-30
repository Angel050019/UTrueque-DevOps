import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../models/usuario_model.dart';

/// Fuente de datos remota: única capa que importa `supabase_flutter`
/// directamente. Traduce las excepciones de Supabase a [Failure]s de
/// dominio para que el resto de la app no dependa de ese paquete.
abstract class AuthRemoteDataSource {
  Future<UsuarioModel> registrar({required String correo, required String contrasena});
  Future<UsuarioModel> iniciarSesion({required String correo, required String contrasena});
  Future<void> cerrarSesion();
  UsuarioModel? get usuarioActual;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UsuarioModel> registrar({required String correo, required String contrasena}) async {
    try {
      final AuthResponse respuesta = await _client.auth.signUp(
        email: correo,
        password: contrasena,
      );
      final User? usuario = respuesta.user;
      if (usuario == null) {
        throw const ServidorFailure('No se pudo crear la cuenta. Inténtalo de nuevo.');
      }
      return UsuarioModel.fromSupabaseUser(usuario);
    } on AuthException catch (e) {
      throw ServidorFailure(e.message);
    }
  }

  @override
  Future<UsuarioModel> iniciarSesion({required String correo, required String contrasena}) async {
    try {
      final AuthResponse respuesta = await _client.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );
      final User? usuario = respuesta.user;
      if (usuario == null) {
        throw const CredencialesInvalidasFailure();
      }
      final Map<String, dynamic>? perfil = await _client
          .from('usuarios')
          .select()
          .eq('id', usuario.id)
          .maybeSingle();
      return UsuarioModel.fromSupabaseUser(usuario, perfil: perfil);
    } on AuthException catch (_) {
      throw const CredencialesInvalidasFailure();
    }
  }

  @override
  Future<void> cerrarSesion() => _client.auth.signOut();

  @override
  UsuarioModel? get usuarioActual {
    final User? usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    return UsuarioModel.fromSupabaseUser(usuario);
  }
}
