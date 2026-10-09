import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/foto_articulo.dart';
import '../errors/publicacion_failures.dart';
import '../repositories/publicacion_repository.dart';
import '../validators/publicacion_validator.dart';

/// Caso de uso: validar y subir las fotos del artículo, en orden.
///
/// - Valida TODAS antes de subir la primera (JPG/PNG, máx. 5 MB, de 1 a 5).
/// - Si una subida falla, borra las que ya se habían subido para no dejar
///   archivos sueltos en Storage, y avisa del error.
/// Devuelve las rutas dentro del bucket, en el mismo orden.
class SubirFotosPublicacion {
  SubirFotosPublicacion(this._repository, this._networkInfo, [PublicacionValidator? validador])
      : _validador = validador ?? const PublicacionValidator();

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;
  final PublicacionValidator _validador;

  Future<List<String>> call(List<FotoArticulo> fotos) async {
    if (fotos.isEmpty) {
      throw const PublicacionInvalidaFailure(
        {CampoPublicacion.fotos: PublicacionValidator.mensajeSinFotos},
      );
    }
    if (fotos.length > AppConstants.fotosPorPublicacionMaximo) {
      throw const DemasiadasFotosFailure();
    }
    for (final FotoArticulo foto in fotos) {
      final Failure? error = _validador.validarFoto(foto);
      if (error != null) throw error;
    }
    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }

    final List<String> subidas = <String>[];
    try {
      for (final FotoArticulo foto in fotos) {
        subidas.add(await _repository.subirFoto(foto));
      }
      return subidas;
    } catch (_) {
      await eliminarSinFallar(_repository, subidas);
      rethrow;
    }
  }
}

/// Borra [rutas] sin lanzar error: es limpieza "de mejor esfuerzo" y no
/// debe tapar el error original que la provocó.
Future<void> eliminarSinFallar(PublicacionRepository repository, List<String> rutas) async {
  if (rutas.isEmpty) return;
  try {
    await repository.eliminarFotos(rutas);
  } catch (_) {
    // Si tampoco se pudieron borrar, quedan en la carpeta del propio
    // usuario; no afectan a nadie más.
  }
}
