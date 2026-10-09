import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/categoria.dart';
import '../repositories/publicacion_repository.dart';

/// Caso de uso: traer el catálogo de categorías para el selector.
class ObtenerCategorias {
  ObtenerCategorias(this._repository, this._networkInfo);

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;

  Future<List<Categoria>> call() async {
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }
    return _repository.obtenerCategorias();
  }
}
