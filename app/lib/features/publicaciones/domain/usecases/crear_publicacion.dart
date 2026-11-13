import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/borrador_publicacion.dart';
import '../entities/publicacion.dart';
import '../errors/publicacion_failures.dart';
import '../repositories/publicacion_repository.dart';
import '../validators/publicacion_validator.dart';
import 'subir_fotos_publicacion.dart';

/// Caso de uso: publicar un artículo (HU-03, issue #4).
///
/// Orden de trabajo:
/// 1. Valida TODO el formulario sin tocar la red. Si algo falla lanza
///    [PublicacionInvalidaFailure] con el error de cada campo.
/// 2. Revisa la conexión (Escenario 6).
/// 3. Sube las fotos.
/// 4. Crea la publicación con UNA sola petición (POST → 201 Created).
///    Si falla, borra las fotos recién subidas.
///
/// SEGURIDAD: fallar de forma segura (no deja datos a medias) y validar
/// antes de tocar la red.
class CrearPublicacion {
  CrearPublicacion(
    PublicacionRepository repository,
    NetworkInfo networkInfo, {
    SubirFotosPublicacion? subirFotos,
    PublicacionValidator? validador,
  })  : _repository = repository,
        _networkInfo = networkInfo,
        _validador = validador ?? const PublicacionValidator(),
        _subirFotos = subirFotos ?? SubirFotosPublicacion(repository, networkInfo, validador);

  final PublicacionRepository _repository;
  final NetworkInfo _networkInfo;
  final PublicacionValidator _validador;
  final SubirFotosPublicacion _subirFotos;

  Future<Publicacion> call(BorradorPublicacion borrador) async {
    final Map<CampoPublicacion, String> errores = _validador.validar(borrador);
    if (errores.isNotEmpty) throw PublicacionInvalidaFailure(errores);

    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }

    final List<String> rutas = await _subirFotos(borrador.fotos);
    try {
      return await _repository.crearPublicacion(
        titulo: borrador.titulo.trim(),
        descripcion: borrador.descripcion.trim(),
        categoriaId: borrador.categoria!.id,
        modalidad: borrador.modalidad!,
        precio: borrador.modalidad!.requierePrecio
            ? _validador.leerPrecio(borrador.precioTexto)
            : null,
        fotos: rutas,
      );
    } on Failure {
      await eliminarSinFallar(_repository, rutas);
      rethrow;
    } catch (_) {
      await eliminarSinFallar(_repository, rutas);
      throw const ServidorFailure();
    }
  }
}
