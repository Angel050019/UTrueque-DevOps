import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/subir_fotos_publicacion.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late SubirFotosPublicacion subirFotos;

  setUpAll(() => registerFallbackValue(fotoJpg()));

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    subirFotos = SubirFotosPublicacion(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
  });

  group('SubirFotosPublicacion', () {
    test('sube las fotos en orden y devuelve sus rutas', () async {
      // ARRANGE
      final List<String> rutas = [rutaFoto1, rutaFoto2];
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async => rutas.removeAt(0));

      // ACT
      final List<String> resultado = await subirFotos([fotoJpg(), fotoPng()]);

      // ASSERT
      expect(resultado, [rutaFoto1, rutaFoto2]);
    });

    test('Escenario 4: con una foto de más de 5 MB no sube ninguna', () async {
      // ACT
      final Future<List<String>> intento = subirFotos([fotoJpg(), fotoMayorA5MB()]);

      // ASSERT
      await expectLater(intento, throwsA(isA<FotoArticuloDemasiadoGrandeFailure>()));
      verifyNever(() => repositorio.subirFoto(any()));
    });

    test('rechaza la lista vacía, más de 5 fotos y archivos que no son imagen', () async {
      await expectLater(subirFotos([]), throwsA(isA<PublicacionInvalidaFailure>()));
      await expectLater(
        subirFotos(List.generate(6, (_) => fotoJpg())),
        throwsA(isA<DemasiadasFotosFailure>()),
      );
      await expectLater(subirFotos([fotoGif()]), throwsA(isA<FotoFormatoInvalidoFailure>()));
      verifyNever(() => repositorio.subirFoto(any()));
    });

    test('Escenario 6: sin conexión no sube nada', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(subirFotos([fotoJpg()]), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repositorio.subirFoto(any()));
    });

    test('si falla la segunda foto, borra la primera y avisa el error', () async {
      // ARRANGE
      int llamada = 0;
      when(() => repositorio.subirFoto(any())).thenAnswer((_) async {
        if (llamada++ == 0) return rutaFoto1;
        throw const ServidorFailure('No se pudo subir la foto. Inténtalo de nuevo.');
      });
      when(() => repositorio.eliminarFotos(any())).thenAnswer((_) async {});

      // ACT
      final Future<List<String>> intento = subirFotos([fotoJpg(), fotoPng()]);

      // ASSERT
      await expectLater(intento, throwsA(isA<ServidorFailure>()));
      verify(() => repositorio.eliminarFotos(const [rutaFoto1])).called(1);
    });

    test('si falla la primera foto no intenta borrar nada', () async {
      // ARRANGE
      when(() => repositorio.subirFoto(any()))
          .thenAnswer((_) async => throw const FotoArticuloDemasiadoGrandeFailure());

      // ACT + ASSERT
      await expectLater(subirFotos([fotoJpg()]), throwsA(isA<FotoArticuloDemasiadoGrandeFailure>()));
      verifyNever(() => repositorio.eliminarFotos(any()));
    });
  });
}
