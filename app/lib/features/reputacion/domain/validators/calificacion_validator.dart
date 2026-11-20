import '../../../../core/utils/caracteres_permitidos.dart';

/// Reglas de una calificación (HU-09, Escenario 12). La base de datos revisa
/// las mismas: de 1 a 5 estrellas y un comentario opcional de hasta 200
/// caracteres con la lista de caracteres permitidos de la descripción
/// (Sprint 6).
class CalificacionValidator {
  const CalificacionValidator();

  static const int longitudMaxima = 200;

  static const String mensajeEstrellas = 'Elige de 1 a 5 estrellas.';
  static const String mensajeLargo = 'El comentario no puede tener más de $longitudMaxima caracteres.';
  static const String mensajeCaracteres = 'El comentario solo puede tener letras, números, espacios, '
      'saltos de línea y estos signos: ${CaracteresPermitidos.signosVisibles}';

  /// `null` si [estrellas] es válido; si no, el mensaje.
  String? validarEstrellas(int? estrellas) =>
      estrellas == null || estrellas < 1 || estrellas > 5 ? mensajeEstrellas : null;

  /// `null` si el [comentario] es válido (vacío también lo es: es opcional).
  String? validarComentario(String comentario) {
    final String limpio = comentario.trim();
    if (limpio.isEmpty) return null;
    if (limpio.length > longitudMaxima) return mensajeLargo;
    if (!CaracteresPermitidos.esDescripcionValida(limpio)) return mensajeCaracteres;
    return null;
  }

  /// El comentario como se envía: sin espacios de más, o `null` si está vacío.
  String? limpiar(String? comentario) {
    final String limpio = (comentario ?? '').trim();
    return limpio.isEmpty ? null : limpio;
  }

  /// ¿Se puede presionar "Enviar calificación"?
  bool sePuedeEnviar(int? estrellas, String comentario) =>
      validarEstrellas(estrellas) == null && validarComentario(comentario) == null;
}
