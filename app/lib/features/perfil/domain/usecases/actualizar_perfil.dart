import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/carrera.dart';
import '../entities/division.dart';
import '../entities/foto_perfil.dart';
import '../entities/perfil.dart';
import '../repositories/perfil_repository.dart';
import '../validators/perfil_validator.dart';
import 'subir_foto_perfil.dart';

/// Caso de uso: completar o editar el perfil académico (HU-02).
///
/// Orden de trabajo:
/// 1. Valida TODO (nombre, división, carrera y foto) sin tocar la red.
/// 2. Revisa la conexión.
/// 3. Si hay foto nueva, la sube primero.
/// 4. Guarda el perfil y devuelve el perfil actualizado.
class ActualizarPerfil {
  ActualizarPerfil(
    PerfilRepository repository,
    NetworkInfo networkInfo, {
    SubirFotoPerfil? subirFoto,
    PerfilValidator? validador,
  })  : _repository = repository,
        _networkInfo = networkInfo,
        _validador = validador ?? const PerfilValidator(),
        _subirFoto = subirFoto ?? SubirFotoPerfil(repository, networkInfo, validador);

  final PerfilRepository _repository;
  final NetworkInfo _networkInfo;
  final PerfilValidator _validador;
  final SubirFotoPerfil _subirFoto;

  Future<Perfil> call({
    required String nombre,
    required Division? division,
    required Carrera? carrera,
    FotoPerfil? fotoNueva,
  }) async {
    final Failure? error = _validador.validarNombre(nombre) ??
        _validador.validarDivisionYCarrera(division, carrera) ??
        _validador.validarFoto(fotoNueva);
    if (error != null) throw error;

    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }

    String? fotoUrl;
    if (fotoNueva != null) {
      fotoUrl = await _subirFoto(fotoNueva);
    }

    return _repository.actualizarPerfil(
      nombreMostrar: nombre.trim(),
      divisionId: division!.id,
      carreraId: carrera!.id,
      fotoUrl: fotoUrl,
    );
  }
}
