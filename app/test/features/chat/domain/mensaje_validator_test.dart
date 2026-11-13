import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/features/chat/domain/validators/mensaje_validator.dart';

void main() {
  const MensajeValidator v = MensajeValidator();

  group('MensajeValidator (HU-07, Escenario 10)', () {
    test('un mensaje normal, con acentos, signos y saltos de línea, es válido', () {
      expect(v.validar('¡Hola! ¿Sigue disponible?\nTe la compro en \$300.'), isNull);
      expect(v.sePuedeEnviar('Sí, nos vemos a las 12:30.'), isTrue);
    });

    test('vacío o solo espacios: "Escribe un mensaje."', () {
      expect(v.validar(''), MensajeValidator.mensajeVacio);
      expect(v.validar('   \n  '), MensajeValidator.mensajeVacio);
      expect(v.sePuedeEnviar('  '), isFalse);
    });

    test('500 caracteres se aceptan; 501 no', () {
      expect(v.validar('a' * 500), isNull);
      expect(v.validar('a' * 501), MensajeValidator.mensajeLargo);
    });

    test('los espacios de sobra no cuentan para el largo', () {
      expect(v.validar('  ${'a' * 500}  '), isNull);
    });

    for (final String texto in ['<script>alert(1)</script>', "hola'; drop table x --", 'Gracias 😀', 'a@b', 'x {y}']) {
      test('rechaza "$texto" con el mensaje de caracteres', () {
        expect(v.validar(texto), MensajeValidator.mensajeCaracteres);
      });
    }

    test('los mensajes dicen qué hacer', () {
      expect(MensajeValidator.mensajeLargo, contains('500'));
      expect(MensajeValidator.mensajeLongitud, contains('entre 1 y 500'));
      expect(MensajeValidator.mensajeCaracteres, contains('¿ ? ¡ !'));
    });
  });
}
