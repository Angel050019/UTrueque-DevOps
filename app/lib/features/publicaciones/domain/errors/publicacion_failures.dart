import '../../../../core/errors/failures.dart';

/// Campos del formulario "Publicar artículo". Sirven para marcar en rojo
/// exactamente el campo que tiene el problema (HU-03, Escenarios 2, 3 y 5).
enum CampoPublicacion { titulo, descripcion, categoria, modalidad, precio, fotos }

/// Uno o varios campos no cumplen las reglas. [errores] trae el mensaje de
/// cada campo con problema; la pantalla lo pinta debajo del campo.
class PublicacionInvalidaFailure extends Failure {
  const PublicacionInvalidaFailure(this.errores)
      : super('Revisa los campos marcados en rojo.');

  final Map<CampoPublicacion, String> errores;

  @override
  List<Object?> get props => [mensaje, errores];
}

/// Una foto del artículo pesa más de 5 MB (HU-03, Escenario 4).
class FotoArticuloDemasiadoGrandeFailure extends Failure {
  const FotoArticuloDemasiadoGrandeFailure()
      : super('Cada foto puede pesar máximo 5 MB.');
}

/// Se intentó agregar más fotos de las permitidas.
class DemasiadasFotosFailure extends Failure {
  const DemasiadasFotosFailure() : super('Puedes agregar máximo 5 fotos.');
}

/// La base de datos rechazó la publicación por no cumplir sus reglas
/// (precio, fotos, longitudes). Es la segunda línea de defensa: normalmente
/// la app ya lo detectó antes de enviar.
class PublicacionRechazadaFailure extends Failure {
  const PublicacionRechazadaFailure()
      : super('El servidor rechazó la publicación. Revisa el precio, las fotos y los textos.');
}

/// El servidor no dejó publicar por permisos (RLS). Pasa cuando el perfil
/// académico todavía no está completo.
class PublicarSinPermisoFailure extends Failure {
  const PublicarSinPermisoFailure()
      : super('Completa tu perfil académico antes de publicar.');
}

/// Cambio de estado no permitido por el ciclo de vida (patrón State).
class TransicionNoPermitidaFailure extends Failure {
  const TransicionNoPermitidaFailure(String desde, String hacia)
      : super('Una publicación $desde no puede pasar a $hacia.');
}
