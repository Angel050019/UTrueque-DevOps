import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/utils/email_validator.dart';

void main() {
 const EmailValidator validador = EmailValidator();

  group('EmailValidator.esInstitucional', () {
    test('acepta un correo con el dominio institucional', () {
      expect(validador.esInstitucional('juan.perez@alumno.utsjr.edu.mx'), isTrue);
    });

    test('acepta el dominio institucional sin importar mayúsculas', () {
      expect(validador.esInstitucional('Juan.Perez@ALUMNO.UTSJR.EDU.MX'), isTrue);
    });

    test('rechaza un correo con otro dominio', () {
      expect(validador.esInstitucional('juan.perez@gmail.com'), isFalse);
    });
  });

  group('EmailValidator.validar', () {
    test('retorna null para un correo institucional válido', () {
      expect(validador.validar('ana.lopez@alumno.utsjr.edu.mx'), isNull);
    });

    test('retorna mensaje de campo vacío', () {
      expect(validador.validar(''), 'Ingresa tu correo institucional.');
    });

    test('retorna mensaje de formato inválido', () {
      expect(validador.validar('no-es-un-correo'), 'Ingresa un correo con formato válido.');
    });

    test('retorna mensaje de dominio no institucional', () {
      expect(
        validador.validar('ana.lopez@hotmail.com'),
        'Debes usar tu correo institucional para registrarte.',
      );
    });
  });
}
