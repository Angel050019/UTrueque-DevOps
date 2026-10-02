import 'package:flutter_test/flutter_test.dart';
import 'package:utrueque/core/constants/app_constants.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/perfil/domain/validators/perfil_validator.dart';

import '../fixtures.dart';

void main() {
  const PerfilValidator validador = PerfilValidator();

  group('validarNombre (3 a 50 caracteres)', () {
    test('acepta un nombre válido', () {
      expect(validador.validarNombre('Ana López'), isNull);
    });

    test('rechaza nombre vacío o solo espacios', () {
      expect(validador.validarNombre('   '), isA<NombreInvalidoFailure>());
    });

    test('rechaza nombre de menos de 3 caracteres (sin contar espacios)', () {
      expect(validador.validarNombre('  Al  '), isA<NombreInvalidoFailure>());
    });

    test('acepta exactamente 3 y 50 caracteres', () {
      expect(validador.validarNombre('Ana'), isNull);
      expect(validador.validarNombre('a' * AppConstants.nombreLongitudMaxima), isNull);
    });

    test('rechaza más de 50 caracteres', () {
      expect(
        validador.validarNombre('a' * (AppConstants.nombreLongitudMaxima + 1)),
        isA<NombreInvalidoFailure>(),
      );
    });
  });

  group('validarDivisionYCarrera', () {
    test('acepta una carrera que pertenece a la división', () {
      expect(validador.validarDivisionYCarrera(divisionTI, carreraSoftware), isNull);
    });

    test('exige división', () {
      expect(validador.validarDivisionYCarrera(null, carreraSoftware),
          const DivisionRequeridaFailure());
    });

    test('exige carrera', () {
      expect(validador.validarDivisionYCarrera(divisionTI, null), const CarreraRequeridaFailure());
    });

    test('rechaza una carrera de otra división (Escenario 2)', () {
      expect(validador.validarDivisionYCarrera(divisionTI, carreraMecatronica),
          const CarreraNoPerteneceFailure());
    });
  });

  group('validarFoto (opcional, JPG/PNG, máx. 5 MB)', () {
    test('sin foto es válido', () {
      expect(validador.validarFoto(null), isNull);
    });

    test('acepta JPG y PNG', () {
      expect(validador.validarFoto(fotoJpg()), isNull);
      expect(validador.validarFoto(fotoPng()), isNull);
    });

    test('acepta exactamente 5 MB', () {
      expect(validador.validarFoto(fotoJpg(AppConstants.tamanoMaximoImagenBytes)), isNull);
    });

    test('rechaza más de 5 MB (Escenario 3)', () {
      expect(validador.validarFoto(fotoMayorA5MB()), const FotoDemasiadoGrandeFailure());
    });

    test('rechaza otro formato aunque la extensión diga .jpg', () {
      expect(validador.validarFoto(fotoGif()), const FotoFormatoInvalidoFailure());
    });
  });
}
