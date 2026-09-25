import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/usuario.dart';

/// Modelo de datos: sabe cómo construirse a partir de un [User] de
/// Supabase y, opcionalmente, de una fila de la tabla `usuarios`.
class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.correo,
    super.nombreMostrar,
    super.division,
    super.carrera,
    super.correoConfirmado,
  });

  factory UsuarioModel.fromSupabaseUser(User usuarioSupabase, {Map<String, dynamic>? perfil}) {
    return UsuarioModel(
      id: usuarioSupabase.id,
      correo: usuarioSupabase.email ?? '',
      correoConfirmado: usuarioSupabase.emailConfirmedAt != null,
      nombreMostrar: perfil?['nombre_mostrar'] as String?,
      division: perfil?['division'] as String?,
      carrera: perfil?['carrera'] as String?,
    );
  }
}
