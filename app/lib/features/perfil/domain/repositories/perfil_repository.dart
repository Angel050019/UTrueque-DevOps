import '../entities/division.dart';
import '../entities/foto_perfil.dart';
import '../entities/perfil.dart';

/// Contrato de datos del perfil académico. La capa de dominio y la de
/// presentación solo conocen esta interfaz, nunca a Supabase.
/// Todos los métodos lanzan un `Failure` si algo sale mal.
abstract class PerfilRepository {
  /// Perfil del usuario con sesión activa.
  Future<Perfil> obtenerPerfilPropio();

  /// Perfil público de cualquier estudiante (para publicaciones y chat).
  Future<Perfil> obtenerPerfilPorId(String id);

  /// Guarda nombre, división, carrera y (si se envía) la URL de la foto
  /// del usuario con sesión activa. Devuelve el perfil ya guardado.
  Future<Perfil> actualizarPerfil({
    required String nombreMostrar,
    required int divisionId,
    required int carreraId,
    String? fotoUrl,
  });

  /// Sube la foto a `avatars/<id del usuario>/` y devuelve su URL pública.
  Future<String> subirFoto(FotoPerfil foto);

  /// Catálogo de divisiones activas, cada una con sus carreras activas.
  Future<List<Division>> obtenerCatalogoAcademico();
}
