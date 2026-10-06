import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/foto_perfil.dart';
import '../repositories/perfil_repository.dart';
import '../validators/perfil_validator.dart';

/// Caso de uso: validar y subir la foto de perfil.
/// Valida formato y tamaño ANTES de tocar la red. Devuelve la URL pública.
class SubirFotoPerfil {
  SubirFotoPerfil(this._repository, this._networkInfo, [PerfilValidator? validador])
      : _validador = validador ?? const PerfilValidator();

  final PerfilRepository _repository;
  final NetworkInfo _networkInfo;
  final PerfilValidator _validador;

  Future<String> call(FotoPerfil foto) async {
    final Failure? error = _validador.validarFoto(foto);
    if (error != null) throw error;
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.subirFoto(foto);
  }
}
