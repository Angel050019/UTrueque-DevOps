import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/division.dart';
import '../repositories/perfil_repository.dart';

/// Caso de uso: obtener el catálogo División → Carrera para los selectores.
class ObtenerCatalogoAcademico {
  ObtenerCatalogoAcademico(this._repository, this._networkInfo);

  final PerfilRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<Division>> call() async {
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerCatalogoAcademico();
  }
}
