import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utrueque/core/errors/failures.dart';
import 'package:utrueque/features/publicaciones/domain/entities/estado_publicacion.dart';
import 'package:utrueque/features/publicaciones/domain/errors/publicacion_failures.dart';
import 'package:utrueque/features/publicaciones/domain/usecases/borrar_publicacion.dart';

import '../fixtures.dart';

void main() {
  late MockPublicacionRepository repositorio;
  late MockNetworkInfo red;
  late BorrarPublicacion borrar;

  setUp(() {
    repositorio = MockPublicacionRepository();
    red = MockNetworkInfo();
    borrar = BorrarPublicacion(repositorio, red);
    when(() => red.estaConectado).thenAnswer((_) async => true);
    when(() => repositorio.borrarPublicacion(any()))
        .thenAnswer((_) async => const [rutaFoto1, rutaFoto2]);
    when(() => repositorio.eliminarFotos(any())).thenAnswer((_) async {});
  });

  group('BorrarPublicacion (HU-06)', () {
    test('Escenario 8: borra la publicación y después sus fotos', () async {
      // ACT
      await borrar(miPublicacion('p1'));

      // ASSERT
      verifyInOrder([
        () => repositorio.borrarPublicacion('p1'),
        () => repositorio.eliminarFotos(const [rutaFoto1, rutaFoto2]),
      ]);
    });

    test('Escenario 8: si fallan las fotos, la publicación ya se borró y no hay error', () async {
      // ARRANGE
      when(() => repositorio.eliminarFotos(any())).thenThrow(const ServidorFailure());

      // ACT + ASSERT
      await expectLater(borrar(miPublicacion('p1')), completes);
      verify(() => repositorio.borrarPublicacion('p1')).called(1);
    });

    test('Escenario 9: una Reservada o una Vendida no se borran ni llaman al servidor', () async {
      for (final EstadoPublicacion estado in const [Reservado(), Vendido()]) {
        // ACT + ASSERT
        await expectLater(
          borrar(miPublicacion('p1', estado: estado)),
          throwsA(isA<AccionNoPermitidaFailure>()),
        );
      }
      verifyNever(() => repositorio.borrarPublicacion(any()));
    });

    test('Escenario 10: si no es suya, no borra fotos', () async {
      // ARRANGE
      when(() => repositorio.borrarPublicacion(any())).thenThrow(const ModificarSinPermisoFailure());

      // ACT + ASSERT
      await expectLater(borrar(miPublicacion('p1')), throwsA(isA<ModificarSinPermisoFailure>()));
      verifyNever(() => repositorio.eliminarFotos(any()));
    });

    test('Escenario 12: sin conexión no llama al servidor', () async {
      // ARRANGE
      when(() => red.estaConectado).thenAnswer((_) async => false);

      // ACT + ASSERT
      await expectLater(borrar(miPublicacion('p1')), throwsA(isA<SinConexionFailure>()));
      verifyNever(() => repositorio.borrarPublicacion(any()));
    });
  });
}
