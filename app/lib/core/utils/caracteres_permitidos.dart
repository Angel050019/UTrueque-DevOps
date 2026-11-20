/// SEGURIDAD: validación de entrada con una lista de caracteres permitidos.
///
/// En lugar de intentar adivinar qué símbolos son peligrosos, se acepta solo
/// lo que hace falta en cada campo y se rechaza todo lo demás (por ejemplo
/// `< > { } [ ] \ | ` ~ ^ = * & @ _ ; ' "`, emojis y caracteres invisibles).
///
/// La base de datos revisa exactamente las mismas reglas
/// (supabase/migrations/20261030120000_validacion_caracteres.sql), así que
/// nadie puede saltárselas llamando al API sin la app.
///
/// La contraseña NO se limita: los caracteres especiales la hacen más
/// fuerte y nunca se guarda ni se muestra como texto.
class CaracteresPermitidos {
  CaracteresPermitidos._();

  /// Letras del español: sin acentos, con acentos, ñ y ü.
  static const String _letras = 'A-Za-zÁÉÍÓÚÜÑáéíóúüñ';

  /// Signos que sí se usan al describir un artículo. El guion va al final
  /// para que no se lea como un rango.
  static const String _signos = r' .,()/#+:%°$¿?¡!\-';

  /// Para los mensajes de error.
  static const String signosVisibles = r'. , - ( ) / # + : % ° $ ¿ ? ¡ !';

  // ---------------------------------------------------------------------
  // Un solo carácter: lo usan los filtros de escritura de cada campo
  // (no dejan teclear ni pegar lo que no está aquí).
  // ---------------------------------------------------------------------

  static final RegExp caracterTitulo = RegExp('[${_letras}0-9$_signos]');
  static final RegExp caracterDescripcion = RegExp('[${_letras}0-9$_signos\n]');
  static final RegExp caracterNombre = RegExp('[$_letras .\\-]');
  static final RegExp caracterBusqueda = RegExp('[${_letras}0-9 ]');
  static final RegExp caracterPrecio = RegExp(r'[0-9.,$ ]');
  static final RegExp caracterCorreo = RegExp(r'[A-Za-z0-9._@\-]');

  // ---------------------------------------------------------------------
  // Texto completo: lo usan los validadores antes de enviar.
  // ---------------------------------------------------------------------

  static final RegExp _titulo = RegExp('^[${_letras}0-9$_signos]*\$');
  static final RegExp _descripcion = RegExp('^[${_letras}0-9$_signos\n]*\$');
  static final RegExp _nombre = RegExp('^[$_letras .\\-]*\$');

  /// Título de una publicación: letras, números, espacios y [signosVisibles].
  static bool esTituloValido(String texto) => _titulo.hasMatch(texto);

  /// Descripción: lo mismo que el título, más saltos de línea.
  static bool esDescripcionValida(String texto) => _descripcion.hasMatch(texto);

  /// Nombre a mostrar: letras, espacios, punto y guion.
  static bool esNombreValido(String texto) => _nombre.hasMatch(texto);
}
