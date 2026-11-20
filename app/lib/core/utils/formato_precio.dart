/// Convierte un precio en texto para mostrarlo: `$150`, `$150.50`,
/// `$1,200`. Sin centavos cuando son cero.
String formatearPrecio(double precio) {
  final int centavos = (precio * 100).round();
  final int pesos = centavos ~/ 100;
  final int resto = centavos % 100;

  final String digitos = pesos.toString();
  final StringBuffer conComas = StringBuffer();
  for (int i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) conComas.write(',');
    conComas.write(digitos[i]);
  }

  if (resto == 0) return '\$$conComas';
  return '\$$conComas.${resto.toString().padLeft(2, '0')}';
}
