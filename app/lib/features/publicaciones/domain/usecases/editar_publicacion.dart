import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../entities/borrador_publicacion.dart';
import '../entities/publicacion.dart';
import '../errors/publicacion_failures.dart';
import '../repositories/publicacion_repository.dart';
import '../validators/publicacion_validator.dart';
import 'subir_fotos_publicacion.dart';

/// Caso de uso: guardar los cambios de una publicación Disponible
/// (HU-06, Escenarios 6 y 7). Reutiliza las reglas de "Publicar artículo".
///
/// Orden de trabajo:
/// 1. Solo una publicación Disponible se edita (patrón State).
/// 2. Valida TODO el formulario sin tocar la red (Escenario 7).
/// 3. Revisa la conexión (Escenario 12).
/// 4. Sube solo las fotos nuevas; las que ya estaban conservan su ruta.
/// 5. Guarda con una sola petición (PATCH). Si falla, borra las fotos
///    nuevas que se alcanzaron a subir (Escenario 13).
/// 6. Si se guardó, borra de Storage las fotos que el estudiante quitó.
///
/// SEGURIDAD: fallar de forma segura y validar antes de tocar la red.
class EditarPublicacion {
  EditarPublicacion(
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

  Future<Publicacion> call(Publicacion original, BorradorPublicacion borrador) async {
    if (!original.estado.sePuedeEditar) throw const AccionNoPermitidaFailure();

    final Map<CampoPublicacion, String> errores = _validador.validar(borrador);
    if (errores.isNotEmpty) throw PublicacionInvalidaFailure(errores);

    if (!await _networkInfo.estaConectado) {
      throw const SinConexionFailure();
    }

    final List<String> rutas = await _subirFotos(borrador.fotos);
    final List<String> nuevas =
        rutas.where((ruta) => !original.fotos.contains(ruta)).toList(growable: false);
    final Publicacion guardada;
    try {
      guardada = await _repository.editarPublicacion(
        id: original.id,
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
      await eliminarSinFallar(_repository, nuevas);
      rethrow;
    } catch (_) {
      await eliminarSinFallar(_repository, nuevas);
      throw const GestionarPublicacionFailure();
    }

    // Las fotos que se quitaron ya no las usa nadie.
    await eliminarSinFallar(
      _repository,
      original.fotos.where((ruta) => !rutas.contains(ruta)).toList(growable: false),
    );
    return guardada;
  }
}
