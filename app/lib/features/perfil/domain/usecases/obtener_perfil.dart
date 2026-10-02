import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/perfil.dart';
import '../repositories/perfil_repository.dart';

/// Caso de uso: obtener un perfil académico.
/// Sin [id] devuelve el perfil propio; con [id], el de otro estudiante.
class ObtenerPerfil {
  ObtenerPerfil(this._repository, this._networkInfo);

  final PerfilRepository _repository;
  final NetworkInfo _networkInfo;

  Future<Perfil> call({String? id}) async {
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    if (id == null) return _repository.obtenerPerfilPropio();
    return _repository.obtenerPerfilPorId(id);
  }
}
