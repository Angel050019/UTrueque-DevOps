import 'package:equatable/equatable.dart';

/// Entidad de dominio: representa a un usuario autenticado de UTrueque.
/// No conoce nada de Supabase ni de la capa de datos.
class Usuario extends Equatable {
  const Usuario({
    required this.id,
    required this.correo,
    this.nombreMostrar,
    this.division,
    this.carrera,
    this.correoConfirmado = false,
  });

  final String id;
  final String correo;
  final String? nombreMostrar;
  final String? division;
  final String? carrera;
  final bool correoConfirmado;

  @override
  List<Object?> get props => [id, correo, nombreMostrar, division, carrera, correoConfirmado];
}
