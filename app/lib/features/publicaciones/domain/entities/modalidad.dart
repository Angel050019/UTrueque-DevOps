/// Cómo se ofrece un artículo. El [valor] es el texto que se guarda en la
/// columna `modalidad` de la tabla `publicaciones`.
enum Modalidad {
  venta('venta', 'Venta'),
  intercambio('intercambio', 'Intercambio'),
  gratis('gratis', 'Gratis');

  const Modalidad(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  /// Solo la venta lleva precio.
  bool get requierePrecio => this == Modalidad.venta;

  /// Convierte el texto de la base de datos en la modalidad.
  static Modalidad desdeValor(String valor) {
    return Modalidad.values.firstWhere(
      (m) => m.valor == valor,
      orElse: () => throw ArgumentError.value(valor, 'valor', 'Modalidad desconocida'),
    );
  }
}
