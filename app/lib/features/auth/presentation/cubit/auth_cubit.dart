import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/iniciar_sesion.dart';
import '../../domain/usecases/registrar_usuario.dart';
import 'auth_state.dart';

/// Orquesta el flujo de registro/login de HU-01 para la capa de
/// presentación. No sabe nada de Supabase: solo llama a los casos de uso.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required RegistrarUsuario registrarUsuario,
    required IniciarSesion iniciarSesion,
  })  : _registrarUsuario = registrarUsuario,
        _iniciarSesion = iniciarSesion,
        super(const AuthInicial());

  final RegistrarUsuario _registrarUsuario;
  final IniciarSesion _iniciarSesion;

  Future<void> registrar({
    required String correo,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    emit(const AuthCargando());
    try {
      final usuario = await _registrarUsuario(
        correo: correo,
        contrasena: contrasena,
        confirmarContrasena: confirmarContrasena,
      );
      emit(AuthRegistroExitoso(usuario));
    } on Failure catch (falla) {
      emit(AuthError(falla));
    } catch (_) {
      emit(const AuthError(ServidorFailure()));
    }
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    emit(const AuthCargando());
    try {
      final usuario = await _iniciarSesion(correo: correo, contrasena: contrasena);
      emit(AuthLoginExitoso(usuario));
    } on Failure catch (falla) {
      emit(AuthError(falla));
    } catch (_) {
      emit(const AuthError(ServidorFailure()));
    }
  }

  void reiniciar() => emit(const AuthInicial());
}
