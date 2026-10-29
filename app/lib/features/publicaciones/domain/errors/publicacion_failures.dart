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

// ---------------------------------------------------------------------------
// HU-04: Feed de publicaciones
// ---------------------------------------------------------------------------

/// No se pudo leer el Feed o el Detalle por un error del servidor
/// (HU-04, Escenario 6). SEGURIDAD: el mensaje no revela detalles internos.
class CargarPublicacionesFailure extends ServidorFailure {
  const CargarPublicacionesFailure()
      : super('No pudimos cargar las publicaciones. Inténtalo de nuevo.');
}

/// La publicación ya no existe: su dueño la borró (HU-04, Escenario 10).
class PublicacionNoEncontradaFailure extends Failure {
  const PublicacionNoEncontradaFailure()
      : super('Esta publicación ya no está disponible.');
}

// ---------------------------------------------------------------------------
// HU-06: Gestión de "Mis publicaciones"
// ---------------------------------------------------------------------------

/// No se pudo leer "Mis publicaciones" por un error del servidor
/// (HU-06, Escenario 13). SEGURIDAD: sin detalles internos.
class CargarMisPublicacionesFailure extends ServidorFailure {
  const CargarMisPublicacionesFailure()
      : super('No pudimos cargar tus publicaciones. Inténtalo de nuevo.');
}

/// No se pudo cambiar el estado, editar o borrar por un error del servidor
/// (HU-06, Escenario 13). SEGURIDAD: sin detalles internos.
class GestionarPublicacionFailure extends ServidorFailure {
  const GestionarPublicacionFailure()
      : super('No pudimos completar la acción. Inténtalo de nuevo.');
}

/// El estado de la publicación ya no permite esa acción: por ejemplo, se
/// vendió desde otro dispositivo (HU-06, Escenario 9). Lo decide el servidor
/// con las mismas reglas del patrón State.
class AccionNoPermitidaFailure extends Failure {
  const AccionNoPermitidaFailure()
      : super('Esa acción ya no es posible: la publicación cambió de estado.');
}

/// La publicación no es del estudiante (o ya no existe): el servidor no
/// modificó nada (HU-06, Escenario 10).
class ModificarSinPermisoFailure extends Failure {
  const ModificarSinPermisoFailure()
      : super('No tienes permiso para modificar esta publicación.');
}
