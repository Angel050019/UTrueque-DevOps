import '../../../../core/utils/caracteres_permitidos.dart';

/// Reglas de un mensaje (HU-07, Escenario 10). La base de datos revisa las
/// mismas: de 1 a 500 caracteres y la lista de caracteres permitidos de la
/// descripción (Sprint 6).
class MensajeValidator {
  const MensajeValidator();

  static const int longitudMaxima = 500;

  static const String mensajeVacio = 'Escribe un mensaje.';
  static const String mensajeLargo = 'El mensaje no puede tener más de $longitudMaxima caracteres.';
  /// Cuando el servidor rechaza la longitud.
  static const String mensajeLongitud = 'El mensaje debe tener entre 1 y $longitudMaxima caracteres.';
  static const String mensajeCaracteres = 'El mensaje solo puede tener letras, números, espacios, '
      'saltos de línea y estos signos: ${CaracteresPermitidos.signosVisibles}';

  /// `null` si [texto] es válido; si no, el mensaje para el estudiante.
  String? validar(String texto) {
    final String limpio = texto.trim();
    if (limpio.isEmpty) return mensajeVacio;
    if (limpio.length > longitudMaxima) return mensajeLargo;
    if (!CaracteresPermitidos.esDescripcionValida(limpio)) return mensajeCaracteres;
    return null;
  }

  /// ¿Se puede presionar "Enviar"?
  bool sePuedeEnviar(String texto) => validar(texto) == null;
}
