import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/utils/caracteres_permitidos.dart';

/// SEGURIDAD: lista de caracteres permitidos. Los mismos ejemplos se
/// prueban en la base de datos (42 + 11 casos SQL).
void main() {
  /// Textos con caracteres que NUNCA se aceptan en título, descripción ni
  /// nombre.
  const List<String> peligrosos = [
    '<script>alert(1)</script>',
    "Calculadora' OR '1'='1",
    'Libro; DROP TABLE x',
    'Bata {talla}',
    'Kit [nuevo]',
    r'Cable \ USB',
    'Libro `raro`',
    'Calculadora "HP"',
    'Precio = 10',
    'Libro *oferta*',
    'Mochila & gorra',
    'correo@utsjr',
    'nombre_archivo',
    'Bata 😀',
    'Libro ~usado',
    'Libro | apuntes',
    'Libro ^2',
    'Libro\tde apuntes',
    'Libro​de apuntes',
  ];

  group('Título', () {
    test('acepta letras con acentos, ñ, ü, números y los signos permitidos', () {
      expect(CaracteresPermitidos.esTituloValido(r'Cálculo Diferencial (2a ed.) ¿nuevo? ¡Sí! #1 + 100% $150'), isTrue);
      expect(CaracteresPermitidos.esTituloValido('Transportador 180° Güemes: kit/escuadras'), isTrue);
      expect(CaracteresPermitidos.esTituloValido('Calculadora Casio fx-991'), isTrue);
    });

    for (final String texto in peligrosos) {
      test('rechaza "$texto"', () => expect(CaracteresPermitidos.esTituloValido(texto), isFalse));
    }

    test('rechaza saltos de línea', () {
      expect(CaracteresPermitidos.esTituloValido('Dos\nlíneas'), isFalse);
    });
  });

  group('Descripción', () {
    test('acepta lo mismo que el título y además saltos de línea', () {
      expect(CaracteresPermitidos.esDescripcionValida('Talla M.\nPoco uso.\n\nEntrego en la UTSJR.'), isTrue);
    });

    for (final String texto in peligrosos) {
      test('rechaza "$texto"', () => expect(CaracteresPermitidos.esDescripcionValida(texto), isFalse));
    }
  });

  group('Nombre a mostrar', () {
    test('acepta letras con acentos, ñ, espacios, punto y guion', () {
      expect(CaracteresPermitidos.esNombreValido('Ma. José Núñez-Güemes'), isTrue);
    });

    for (final String texto in ['Ana2', "O'Brien", 'Ana (TI)', 'Ana!', ...peligrosos]) {
      test('rechaza "$texto"', () => expect(CaracteresPermitidos.esNombreValido(texto), isFalse));
    }
  });

  group('Filtros de escritura (un carácter a la vez)', () {
    bool deja(RegExp filtro, String caracter) => filtro.hasMatch(caracter);

    test('título: deja letras, números y signos permitidos; bloquea los demás', () {
      for (final String c in 'aZñÜé7 .,()/#+:%°\$¿?¡!-'.split('')) {
        expect(deja(CaracteresPermitidos.caracterTitulo, c), isTrue, reason: c);
      }
      for (final String c in '<>{}[]\\|`~^=*&@_;\'"\n\t'.split('')) {
        expect(deja(CaracteresPermitidos.caracterTitulo, c), isFalse, reason: c);
      }
    });

    test('descripción: además deja saltos de línea', () {
      expect(deja(CaracteresPermitidos.caracterDescripcion, '\n'), isTrue);
      expect(deja(CaracteresPermitidos.caracterDescripcion, '<'), isFalse);
    });

    test('nombre: solo letras, espacios, punto y guion', () {
      for (final String c in 'aÑ .-'.split('')) {
        expect(deja(CaracteresPermitidos.caracterNombre, c), isTrue, reason: c);
      }
      for (final String c in '1_\'(!'.split('')) {
        expect(deja(CaracteresPermitidos.caracterNombre, c), isFalse, reason: c);
      }
    });

    test('buscador: solo letras, números y espacios', () {
      expect(deja(CaracteresPermitidos.caracterBusqueda, 'á'), isTrue);
      expect(deja(CaracteresPermitidos.caracterBusqueda, '5'), isTrue);
      expect(deja(CaracteresPermitidos.caracterBusqueda, '%'), isFalse);
      expect(deja(CaracteresPermitidos.caracterBusqueda, '<'), isFalse);
    });

    test(r'precio: solo números, punto, coma, espacio y $', () {
      for (final String c in '09., \$'.split('')) {
        expect(deja(CaracteresPermitidos.caracterPrecio, c), isTrue, reason: c);
      }
      expect(deja(CaracteresPermitidos.caracterPrecio, 'a'), isFalse);
      expect(deja(CaracteresPermitidos.caracterPrecio, '-'), isFalse);
    });

    test('correo: letras, números y . _ @ -', () {
      for (final String c in 'aZ09._@-'.split('')) {
        expect(deja(CaracteresPermitidos.caracterCorreo, c), isTrue, reason: c);
      }
      for (final String c in ' <\'"ñ;'.split('')) {
        expect(deja(CaracteresPermitidos.caracterCorreo, c), isFalse, reason: c);
      }
    });
  });

  test('el mensaje lista los signos permitidos', () {
    expect(CaracteresPermitidos.signosVisibles, contains('¿ ? ¡ !'));
  });
}
