import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/usuario.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInicial extends AuthState {
  const AuthInicial();
}

class AuthCargando extends AuthState {
  const AuthCargando();
}

class AuthRegistroExitoso extends AuthState {
  const AuthRegistroExitoso(this.usuario);
  final Usuario usuario;

  @override
  List<Object?> get props => [usuario];
}

class AuthLoginExitoso extends AuthState {
  const AuthLoginExitoso(this.usuario);
  final Usuario usuario;

  @override
  List<Object?> get props => [usuario];
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
